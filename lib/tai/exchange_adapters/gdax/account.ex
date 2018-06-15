defmodule Tai.ExchangeAdapters.Gdax.Account do
  @moduledoc """
  Execute private exchange actions for the GDAX account
  """
  use Tai.Exchanges.Account

  def all_balances() do
    Tai.ExchangeAdapters.Gdax.Account.AllBalances.fetch()
  end

  def buy_limit(symbol, price, size, time_in_force) do
    Tai.ExchangeAdapters.Gdax.Account.Orders.buy_limit(symbol, price, size, time_in_force)
  end

  def sell_limit(symbol, price, size, time_in_force) do
    Tai.ExchangeAdapters.Gdax.Account.Orders.sell_limit(symbol, price, size, time_in_force)
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
