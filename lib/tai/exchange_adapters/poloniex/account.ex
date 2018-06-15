defmodule Tai.ExchangeAdapters.Poloniex.Account do
  @moduledoc """
  Execute private exchange actions for the Poloniex account
  """
  use Tai.Exchanges.Account

  def all_balances() do
    Tai.ExchangeAdapters.Poloniex.Account.AllBalances.fetch()
  end

  def buy_limit(symbol, price, size, time_in_force) do
    Tai.ExchangeAdapters.Poloniex.Account.Orders.buy_limit(symbol, price, size, time_in_force)
  end

  def sell_limit(symbol, price, size, time_in_force) do
    Tai.ExchangeAdapters.Poloniex.Account.Orders.sell_limit(symbol, price, size, time_in_force)
  end
end
