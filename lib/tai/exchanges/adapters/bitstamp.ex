defmodule Tai.Exchanges.Adapters.Bitstamp do
  defdelegate quotes(symbol), to: Tai.Exchanges.Adapters.Bitstamp.Quotes
  defdelegate price(symbol), to: Tai.Exchanges.Adapters.Bitstamp.Price
  defdelegate balance, to: Tai.Exchanges.Adapters.Bitstamp.Balance
  defdelegate buy_limit(symbol, price, size), to: Tai.Exchanges.Adapters.Bitstamp.Orders
  defdelegate sell_limit(symbol, price, size), to: Tai.Exchanges.Adapters.Bitstamp.Orders
  defdelegate order_status(order_id), to: Tai.Exchanges.Adapters.Bitstamp.OrderStatus
end
