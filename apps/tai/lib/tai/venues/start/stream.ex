defmodule Tai.Venues.Start.Stream do
  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()
  @type account :: Tai.Venues.Account.t()

  @spec start(venue, [product], [account]) :: DynamicSupervisor.on_start_child()
  def start(venue, products, accounts) do
    Tai.Venues.StreamsSupervisor.start(venue, products, accounts)
  end
end
