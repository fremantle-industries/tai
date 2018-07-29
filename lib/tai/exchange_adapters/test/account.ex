defmodule Tai.ExchangeAdapters.Test.Account do
  @moduledoc """
  Mock for testing private exchange actions
  """

  use Tai.Exchanges.Account

  @all_balances %{
    bch: Tai.Exchanges.AssetBalance.new(0, 0),
    btc: Tai.Exchanges.AssetBalance.new("0.10000000", "1.8122774027894548"),
    eth: Tai.Exchanges.AssetBalance.new(0, "0.000000000000200000000"),
    ltc: Tai.Exchanges.AssetBalance.new(0, "0.03")
  }

  def all_balances() do
    {:ok, @all_balances}
  end

  def buy_limit(:btc_usd_success, _price, size, :fok) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.filled(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: size
    }

    {:ok, order_response}
  end

  def buy_limit(:btc_usd_expired, _price, size, :fok) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.expired(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: 0
    }

    {:ok, order_response}
  end

  def buy_limit(:btc_usd_pending, _price, size, :gtc) do
    order_response = %Tai.Trading.OrderResponse{
      id: "f9df7435-34d5-4861-8ddc-80f0fd2c83d7",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: Tai.Trading.TimeInForce.good_til_canceled(),
      original_size: size,
      executed_size: 0.0
    }

    {:ok, order_response}
  end

  def buy_limit(:btc_usd_success, _price, size, time_in_force) do
    order_response = %Tai.Trading.OrderResponse{
      id: "f9df7435-34d5-4861-8ddc-80f0fd2c83d7",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: time_in_force,
      original_size: size,
      executed_size: size
    }

    {:ok, order_response}
  end

  def buy_limit(:btc_usd_insufficient_funds, _price, _size, _time_in_force) do
    error = %Tai.Trading.InsufficientBalanceError{reason: "Insufficient Balance"}
    {:error, error}
  end

  def buy_limit(_symbol, _price, _size, _time_in_force) do
    {:error, :unknown_error}
  end

  def sell_limit(:btc_usd_success, _price, size, :fok) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.filled(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: size
    }

    {:ok, order_response}
  end

  def sell_limit(:btc_usd_expired, _price, size, :fok) do
    order_response = %Tai.Trading.OrderResponse{
      id: UUID.uuid4(),
      status: Tai.Trading.OrderStatus.expired(),
      time_in_force: Tai.Trading.TimeInForce.fill_or_kill(),
      original_size: size,
      executed_size: 0
    }

    {:ok, order_response}
  end

  def sell_limit(:btc_usd_pending, _price, size, :gtc) do
    order_response = %Tai.Trading.OrderResponse{
      id: "41541912-ebc1-4173-afa5-4334ccf7a1a8",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: Tai.Trading.TimeInForce.good_til_canceled(),
      original_size: size,
      executed_size: 0.0
    }

    {:ok, order_response}
  end

  def sell_limit(:btc_usd_success, _price, size, time_in_force) do
    order_response = %Tai.Trading.OrderResponse{
      id: "41541912-ebc1-4173-afa5-4334ccf7a1a8",
      status: Tai.Trading.OrderStatus.pending(),
      time_in_force: time_in_force,
      original_size: size,
      executed_size: size
    }

    {:ok, order_response}
  end

  def sell_limit(:btc_usd_insufficient_funds, _price, _size, _time_in_force) do
    error = %Tai.Trading.InsufficientBalanceError{reason: "Insufficient Balance"}
    {:error, error}
  end

  def sell_limit(_symbol, _price, _size, _time_in_force) do
    {:error, :unknown_error}
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
