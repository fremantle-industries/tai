defmodule Tai.ExchangeAdapters.Gdax.Account do
  @moduledoc """
  Execute private exchange actions for the GDAX account
  """
  use Tai.Exchanges.Account

  def all_balances(credentials) do
    Tai.ExchangeAdapters.Gdax.Account.AllBalances.fetch(credentials)
  end

  def buy_limit(symbol, price, size, time_in_force, credentials) do
    Tai.ExchangeAdapters.Gdax.Account.Orders.buy_limit(
      symbol,
      price,
      size,
      time_in_force,
      credentials
    )
  end

  def sell_limit(symbol, price, size, time_in_force, credentials) do
    Tai.ExchangeAdapters.Gdax.Account.Orders.sell_limit(
      symbol,
      price,
      size,
      time_in_force,
      credentials
    )
  end

  def cancel_order(server_id, credentials) do
    Tai.ExchangeAdapters.Gdax.Account.CancelOrder.execute(server_id, credentials)
  end

  def handle_call({:order_status, order_id}, _from, state) do
    response = Tai.ExchangeAdapters.Gdax.Account.OrderStatus.fetch(order_id, state)
    {:reply, response, state}
  end
end
