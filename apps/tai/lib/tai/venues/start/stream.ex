defmodule Tai.Venues.Start.Stream do
  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()

  @spec start(venue, [product]) :: DynamicSupervisor.on_start_child()
  def start(venue, products) do
    Tai.Venues.StreamsSupervisor.start(venue, products)
  end
end
