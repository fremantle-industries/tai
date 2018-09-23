defmodule Tai.ExchangeAdapters.Binance.Account do
  @moduledoc """
  Execute private exchange actions for the Binance account
  """

  use Tai.Exchanges.Account

  def all_balances(_credentials) do
    Tai.ExchangeAdapters.Binance.Account.AllBalances.fetch()
  end

  def buy_limit(symbol, price, size, time_in_force, _credentials) do
    Tai.ExchangeAdapters.Binance.Account.Orders.buy_limit(symbol, price, size, time_in_force)
  end

  def sell_limit(symbol, price, size, time_in_force, _credentials) do
    Tai.ExchangeAdapters.Binance.Account.Orders.sell_limit(symbol, price, size, time_in_force)
  end

  def cancel_order(_server_id, _credentials) do
    {:error, :not_implemented}
  end
end
