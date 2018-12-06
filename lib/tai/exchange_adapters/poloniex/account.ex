defmodule Tai.ExchangeAdapters.Poloniex.Account do
  @moduledoc """
  Execute private exchange actions for the Poloniex account
  """
  use Tai.Exchanges.Account

  def all_balances(credentials) do
    Tai.ExchangeAdapters.Poloniex.Account.AllBalances.fetch(credentials)
  end

  def create_order(%Tai.Trading.Order{} = order, credentials) do
    Tai.ExchangeAdapters.Poloniex.Account.Orders.create(order, credentials)
  end

  def cancel_order(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end

  def order_status(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end
end
