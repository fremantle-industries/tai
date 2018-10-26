defmodule Tai.VenueAdapters.Poloniex.ProductStatus do
  @type status :: Tai.Exchanges.ProductStatus.t()

  @spec normalize(poloniex_status :: String.t()) :: {:ok, status} | {:error, :unknown_status}
  def normalize(poloniex_status)

  def normalize("0"), do: {:ok, Tai.Exchanges.ProductStatus.trading()}
  def normalize("1"), do: {:ok, Tai.Exchanges.ProductStatus.halt()}
  def normalize(_), do: {:error, :unknown_status}
end
