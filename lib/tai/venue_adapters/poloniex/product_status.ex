defmodule Tai.VenueAdapters.Poloniex.ProductStatus do
  @type status :: Tai.Venues.Product.status()

  @spec normalize(poloniex_status :: String.t()) :: {:ok, status} | {:error, :unknown_status}
  def normalize(poloniex_status)

  def normalize("0"), do: {:ok, Tai.Venues.ProductStatus.trading()}
  def normalize("1"), do: {:ok, Tai.Venues.ProductStatus.halt()}
  def normalize(_), do: {:error, :unknown_status}
end
