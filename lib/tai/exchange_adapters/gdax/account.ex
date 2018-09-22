defmodule Tai.ExchangeAdapters.Gdax.Account do
  @moduledoc """
  Execute private exchange actions for the GDAX account
  """
  use Tai.Exchanges.Account

  def all_balances(account) do
    Tai.ExchangeAdapters.Gdax.Account.AllBalances.fetch(account)
  end

  def buy_limit(symbol, price, size, time_in_force, account) do
    Tai.ExchangeAdapters.Gdax.Account.Orders.buy_limit(
      symbol,
      price,
      size,
      time_in_force,
      account
    )
  end

  def sell_limit(symbol, price, size, time_in_force, account) do
    Tai.ExchangeAdapters.Gdax.Account.Orders.sell_limit(
      symbol,
      price,
      size,
      time_in_force,
      account
    )
  end

  def cancel_order(server_id, account) do
    Tai.ExchangeAdapters.Gdax.Account.CancelOrder.execute(server_id, account)
  end

  def handle_call({:order_status, order_id}, _from, state) do
    response = Tai.ExchangeAdapters.Gdax.Account.OrderStatus.fetch(order_id, state)
    {:reply, response, state}
  end
end
