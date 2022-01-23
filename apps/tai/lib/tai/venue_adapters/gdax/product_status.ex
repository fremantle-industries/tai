defmodule Tai.VenueAdapters.Gdax.ProductStatus do
  @type status :: Tai.Venues.Product.status()
  @type error_reason :: {:unknown_status, String.t()}

  @spec normalize(String.t()) :: {:ok, status} | {:error, error_reason}
  def normalize(venue_status) do
    case venue_status do
      "online" -> {:ok, Tai.Venues.ProductStatus.trading()}
      "delisted" -> {:ok, Tai.Venues.ProductStatus.delisted()}
      _ -> {:error, {:unknown_status, venue_status}}
    end
  end
end
