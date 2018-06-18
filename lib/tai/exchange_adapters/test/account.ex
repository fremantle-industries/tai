defmodule Tai.ExchangeAdapters.Test.Account do
  @moduledoc """
  Mock for testing private exchange actions
  """

  use GenServer

  alias Tai.Exchanges.Account

  def start_link(account_id) do
    GenServer.start_link(__MODULE__, account_id, name: account_id |> Account.to_name())
  end

  def init(account_id) do
    {:ok, account_id}
  end

  @all_balances %{
    bch: Tai.Exchanges.BalanceDetail.new(0, 0),
    btc: Tai.Exchanges.BalanceDetail.new("0.10000000", "1.8122774027894548"),
    eth: Tai.Exchanges.BalanceDetail.new(0, "0.000000000000200000000"),
    ltc: Tai.Exchanges.BalanceDetail.new(0, "0.03")
  }

  def handle_call(:all_balances, _from, state) do
    {:reply, {:ok, @all_balances}, state}
  end

  def handle_call({:buy_limit, :btc_usd_success, _price, size, :fok}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.filled(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: size
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:buy_limit, :btc_usd_expired, _price, size, :fok}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.expired(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: 0
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:buy_limit, :btc_usd_pending, _price, size, :gtc}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: "f9df7435-34d5-4861-8ddc-80f0fd2c83d7",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: Tai.Trading.TimeInForce.good_til_canceled(),
      original_size: size,
      executed_size: 0.0
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:buy_limit, :btc_usd_success, _price, size, time_in_force}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: "f9df7435-34d5-4861-8ddc-80f0fd2c83d7",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: time_in_force,
      original_size: size,
      executed_size: size
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call(
        {:buy_limit, :btc_usd_insufficient_funds, _price, _size, _time_in_force},
        _from,
        state
      ) do
    {
      :reply,
      {:error, %Tai.Trading.InsufficientBalanceError{reason: "Insufficient Balance"}},
      state
    }
  end

  def handle_call({:buy_limit, _symbol, _price, _size, _time_in_force}, _from, state) do
    {:reply, {:error, :unknown_error}, state}
  end

  def handle_call({:sell_limit, :btc_usd_success, _price, size, :fok}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.filled(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: size
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:sell_limit, :btc_usd_expired, _price, size, :fok}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.expired(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: 0
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:sell_limit, :btc_usd_pending, _price, size, :gtc}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: "41541912-ebc1-4173-afa5-4334ccf7a1a8",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: Tai.Trading.TimeInForce.good_til_canceled(),
      original_size: size,
      executed_size: 0.0
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call({:sell_limit, :btc_usd_success, _price, size, time_in_force}, _from, state) do
    order_response = %Tai.Trading.OrderResponse{
      id: "41541912-ebc1-4173-afa5-4334ccf7a1a8",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: time_in_force,
      original_size: size,
      executed_size: size
    }

    {:reply, {:ok, order_response}, state}
  end

  def handle_call(
        {:sell_limit, :btc_usd_insufficient_funds, _price, _size, _time_in_force},
        _from,
        state
      ) do
    {
      :reply,
      {:error, %Tai.Trading.InsufficientBalanceError{reason: "Insufficient Balance"}},
      state
    }
  end

  def handle_call({:sell_limit, _symbol, _price, _size, _time_in_force}, _from, state) do
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
