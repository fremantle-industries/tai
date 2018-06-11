defmodule Tai.ExchangeAdapters.Gdax.Account do
  @moduledoc """
  Execute private exchange actions for the GDAX account
  """

  use GenServer

  def start_link(account_id) do
    GenServer.start_link(
      __MODULE__,
      account_id,
      name: account_id |> Tai.Exchanges.Account.to_name()
    )
  end

  def init(account_id) do
    {:ok, account_id}
  end

  def handle_call(:all_balances, _from, state) do
    {:reply, Tai.ExchangeAdapters.Gdax.Account.AllBalances.fetch(), state}
  end

  def handle_call({:buy_limit, symbol, price, size, time_in_force}, _from, state) do
    response =
      Tai.ExchangeAdapters.Gdax.Account.Orders.buy_limit(
        symbol,
        price,
        size,
        time_in_force
      )

    {:reply, response, state}
  end

  def handle_call({:sell_limit, symbol, price, size, time_in_force}, _from, state) do
    response =
      Tai.ExchangeAdapters.Gdax.Account.Orders.sell_limit(
        symbol,
        price,
        size,
        time_in_force
      )

    {:reply, response, state}
  end

  def handle_call({:order_status, order_id}, _from, state) do
    response = Tai.ExchangeAdapters.Gdax.Account.OrderStatus.fetch(order_id)
    {:reply, response, state}
  end

  def handle_call({:cancel_order, order_id}, _from, state) do
    response = Tai.ExchangeAdapters.Gdax.Account.CancelOrder.execute(order_id)
    {:reply, response, state}
  end
end
