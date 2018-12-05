defmodule Tai.VenueAdapters.Binance.ProductStatus do
  @type status :: Tai.Venues.Product.status()

  @spec normalize(binance_status :: String.t()) :: {:ok, status} | {:error, :unknown_status}
  def normalize(binance_status)

  def normalize("PRE_TRADING"), do: {:ok, Tai.Venues.ProductStatus.pre_trading()}
  def normalize("TRADING"), do: {:ok, Tai.Venues.ProductStatus.trading()}
  def normalize("POST_TRADING"), do: {:ok, Tai.Venues.ProductStatus.post_trading()}
  def normalize("END_OF_DAY"), do: {:ok, Tai.Venues.ProductStatus.end_of_day()}
  def normalize("HALT"), do: {:ok, Tai.Venues.ProductStatus.halt()}
  def normalize("AUCTION_MATCH"), do: {:ok, Tai.Venues.ProductStatus.auction_match()}
  def normalize("BREAK"), do: {:ok, Tai.Venues.ProductStatus.break()}
  def normalize(_), do: {:error, :unknown_status}
end
