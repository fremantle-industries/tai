defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  alias Tai.Commands

  defdelegate help, to: Commands.Info
  defdelegate balance, to: Commands.Balances
  defdelegate markets, to: Commands.Markets
  defdelegate orders, to: Commands.Orders
  defdelegate buy_limit(exchange, symbol, price, size), to: Commands.Trading
  defdelegate sell_limit(exchange, symbol, price, size), to: Commands.Trading
  defdelegate order_status(exchange, order_id), to: Commands.Trading
  defdelegate cancel_order(exchange, order_id), to: Commands.Trading
end
