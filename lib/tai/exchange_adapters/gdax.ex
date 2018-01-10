defmodule Tai.ExchangeAdapters.Gdax do
  defdelegate price(symbol), to: Tai.ExchangeAdapters.Gdax.Price
  defdelegate balance, to: Tai.ExchangeAdapters.Gdax.Balance
  defdelegate buy_limit(symbol, price, size), to: Tai.ExchangeAdapters.Gdax.Orders
  defdelegate sell_limit(symbol, price, size), to: Tai.ExchangeAdapters.Gdax.Orders
  defdelegate order_status(order_id), to: Tai.ExchangeAdapters.Gdax.OrderStatus
  defdelegate cancel_order(order_id), to: Tai.ExchangeAdapters.Gdax.CancelOrder
end
