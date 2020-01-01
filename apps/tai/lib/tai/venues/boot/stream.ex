defmodule Tai.Venues.Boot.Stream do
  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()

  @spec start(venue, [product]) :: DynamicSupervisor.on_start_child()
  def start(venue, products), do: Tai.Venues.StreamsSupervisor.start_stream(venue, products)
end
