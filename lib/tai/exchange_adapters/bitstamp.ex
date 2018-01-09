defmodule Tai.ExchangeAdapters.Bitstamp do
  defdelegate quotes(symbol), to: Tai.ExchangeAdapters.Bitstamp.Quotes
  defdelegate price(symbol), to: Tai.ExchangeAdapters.Bitstamp.Price
  defdelegate balance, to: Tai.ExchangeAdapters.Bitstamp.Balance
  defdelegate buy_limit(symbol, price, size), to: Tai.ExchangeAdapters.Bitstamp.Orders
  defdelegate sell_limit(symbol, price, size), to: Tai.ExchangeAdapters.Bitstamp.Orders
  defdelegate order_status(order_id), to: Tai.ExchangeAdapters.Bitstamp.OrderStatus
  defdelegate cancel_order(order_id), to: Tai.ExchangeAdapters.Bitstamp.CancelOrder
end
