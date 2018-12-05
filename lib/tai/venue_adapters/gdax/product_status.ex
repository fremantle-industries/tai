defmodule Tai.VenueAdapters.Gdax.ProductStatus do
  @type status :: Tai.Venues.Product.status()

  @spec normalize(gdax_status :: String.t()) :: {:ok, status} | {:error, :unknown_status}
  def normalize(gdax_status)

  def normalize("online"), do: {:ok, Tai.Venues.ProductStatus.trading()}
  def normalize(_), do: {:error, :unknown_status}
end
