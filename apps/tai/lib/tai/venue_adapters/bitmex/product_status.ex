defmodule Tai.VenueAdapters.Bitmex.ProductStatus do
  @type status :: Tai.Venues.Product.status()

  @spec normalize(bitmex_state :: String.t()) :: status
  def normalize("Open"), do: Tai.Venues.ProductStatus.trading()
  def normalize("Settled"), do: Tai.Venues.ProductStatus.settled()
  def normalize("Unlisted"), do: Tai.Venues.ProductStatus.delisted()
end
