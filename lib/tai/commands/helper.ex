defmodule Tai.Commands.Helper do
  alias Tai.Commands

  defdelegate help, to: Commands.Info
  defdelegate balance, to: Commands.Balances
  defdelegate order_book_status, to: Commands.Markets
  defdelegate quotes(feed_id_and_symbol), to: Commands.Markets
  defdelegate buy_limit(exchange, symbol, price, size), to: Commands.Orders
  defdelegate sell_limit(exchange, symbol, price, size), to: Commands.Orders
  defdelegate order_status(exchange, order_id), to: Commands.Orders
  defdelegate cancel_order(exchange, order_id), to: Commands.Orders
end
