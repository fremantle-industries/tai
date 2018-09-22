defmodule Tai.ExchangeAdapters.Poloniex.Account do
  @moduledoc """
  Execute private exchange actions for the Poloniex account
  """
  use Tai.Exchanges.Account

  def all_balances(account) do
    Tai.ExchangeAdapters.Poloniex.Account.AllBalances.fetch(account)
  end

  def buy_limit(symbol, price, size, time_in_force, _account) do
    Tai.ExchangeAdapters.Poloniex.Account.Orders.buy_limit(symbol, price, size, time_in_force)
  end

  def sell_limit(symbol, price, size, time_in_force, _account) do
    Tai.ExchangeAdapters.Poloniex.Account.Orders.sell_limit(symbol, price, size, time_in_force)
  end

  def cancel_order(_server_id, _credentials) do
    {:error, :not_implemented}
  end
end
