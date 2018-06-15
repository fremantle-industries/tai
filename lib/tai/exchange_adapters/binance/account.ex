defmodule Tai.ExchangeAdapters.Binance.Account do
  @moduledoc """
  Execute private exchange actions for the Binance account
  """
  use Tai.Exchanges.Account

  def all_balances() do
    Tai.ExchangeAdapters.Binance.Account.AllBalances.fetch()
  end

  def buy_limit(symbol, price, size, time_in_force) do
    Tai.ExchangeAdapters.Binance.Account.Orders.buy_limit(symbol, price, size, time_in_force)
  end

  def sell_limit(symbol, price, size, time_in_force) do
    Tai.ExchangeAdapters.Binance.Account.Orders.sell_limit(symbol, price, size, time_in_force)
  end
end
