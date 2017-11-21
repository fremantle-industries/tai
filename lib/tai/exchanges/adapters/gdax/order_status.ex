defmodule Tai.Exchanges.Adapters.Gdax.OrderStatus do
  def to_atom("pending"), do: :pending
  def to_atom("open"), do: :open
end
