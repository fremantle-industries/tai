defmodule Tai.VenueAdapters.Binance.OrderStatus do
  def from_venue("PARTIALLY_FILLED"), do: :open
  def from_venue("FILLED"), do: :filled
  def from_venue("EXPIRED"), do: :expired
  def from_venue("NEW"), do: :open
  def from_venue("CANCELED"), do: :canceled
end
