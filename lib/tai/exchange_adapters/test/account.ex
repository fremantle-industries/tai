defmodule Tai.ExchangeAdapters.Test.Account do
  @moduledoc """
  Mock for testing private exchange actions
  """

  use GenServer

  alias Tai.{Exchanges.Account, Trading.OrderResponses}

  def start_link(exchange_id) do
    GenServer.start_link(__MODULE__, exchange_id, name: exchange_id |> Account.to_name())
  end

  def init(exchange_id) do
    {:ok, exchange_id}
  end

  def handle_call(:balance, _from, state) do
    {:reply, Decimal.new(0.11), state}
  end

  def handle_call({:buy_limit, :btcusd_success, _price, _size}, _from, state) do
    order_response = %OrderResponses.Created{
      id: "f9df7435-34d5-4861-8ddc-80f0fd2c83d7",
      status: :pending,
      created_at: Timex.now()
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:buy_limit, :btcusd_insufficient_funds, _price, _size}, _from, state) do
    {:reply, {:error, %OrderResponses.InsufficientFunds{}}, state}
  end

  def handle_call({:buy_limit, _symbol, _price, _size}, _from, state) do
    {:reply, {:error, :unknown_error}, state}
  end

  def handle_call({:sell_limit, :btcusd_success, _price, _size}, _from, state) do
    order_response = %OrderResponses.Created{
      id: "41541912-ebc1-4173-afa5-4334ccf7a1a8",
      status: :pending,
      created_at: Timex.now()
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:sell_limit, :btcusd_insufficient_funds, _price, _size}, _from, state) do
    {:reply, {:error, %OrderResponses.InsufficientFunds{}}, state}
  end

  def handle_call({:sell_limit, _symbol, _price, _size}, _from, state) do
    {:reply, {:error, :unknown_error}, state}
  end

  def handle_call({:order_status, "invalid-order-id" = _order_id}, _from, state) do
    {:reply, {:error, "Invalid order id"}, state}
  end

  def handle_call({:order_status, _order_id}, _from, state) do
    {:reply, {:ok, :open}, state}
  end

  def handle_call({:cancel_order, "invalid-order-id" = _order_id}, _from, state) do
    {:reply, {:error, "Invalid order id"}, state}
  end

  def handle_call({:cancel_order, order_id}, _from, state) do
    {:reply, {:ok, order_id}, state}
  end
end
