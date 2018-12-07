defmodule Tai.ExchangeAdapters.Binance.Account do
  @moduledoc """
  Execute private exchange actions for the Binance account
  """

  use Tai.Exchanges.Account

  def create_order(%Tai.Trading.Order{} = order, _credentials) do
    Tai.ExchangeAdapters.Binance.Account.Orders.create(order)
  end

  def cancel_order(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end

  def order_status(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end
end
