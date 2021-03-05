defmodule Tai.VenueAdapters.Ftx.FundingRates do
  alias ExFtx.{Futures}
  alias Tai.VenueAdapters.Ftx

  def funding_rates(venue_id) do
    with {:ok, venue_funding_rates} <- Futures.FundingRates.get() do
      funding_rates = venue_funding_rates |> Enum.map(& build(&1, venue_id))
      {:ok, funding_rates}
    end
  end

  @date_format "{ISO:Extended}"

  defp build(venue_funding_rate, venue_id) do
    venue_product_symbol = venue_funding_rate.future
    product_symbol = venue_product_symbol |> Ftx.Products.to_symbol()
    time = Timex.parse!(venue_funding_rate.time, @date_format)
    rate = Tai.Utils.Decimal.cast!(venue_funding_rate.rate, :normalize)

    %Tai.Venues.FundingRate{
      venue: venue_id,
      venue_product_symbol: venue_product_symbol,
      product_symbol: product_symbol,
      time: time,
      rate: rate
    }
  end
end
