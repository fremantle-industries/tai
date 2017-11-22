defmodule Tai.Exchanges.Adapters.Gdax do
  defdelegate price(symbol), to: Tai.Exchanges.Adapters.Gdax.Price
  defdelegate balance, to: Tai.Exchanges.Adapters.Gdax.Balance
  defdelegate quotes(symbol), to: Tai.Exchanges.Adapters.Gdax.Quotes
  defdelegate buy_limit(symbol, price, size), to: Tai.Exchanges.Adapters.Gdax.Orders
  defdelegate order_status(order_id), to: Tai.Exchanges.Adapters.Gdax.OrderStatus
  defdelegate cancel_order(order_id), to: Tai.Exchanges.Adapters.Gdax.CancelOrder
end
