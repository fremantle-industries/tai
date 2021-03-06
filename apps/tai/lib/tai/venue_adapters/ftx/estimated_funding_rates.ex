defmodule Tai.VenueAdapters.Ftx.EstimatedFundingRates do
  # alias ExFtx.{Futures}
  # alias Tai.VenueAdapters.Ftx

  def estimated_funding_rates(_venue_id) do
    # with {:ok, venue_funding_rates} <- Futures.FundingRates.get() do
    #   funding_rates = venue_funding_rates |> Enum.map(& build(&1, venue_id))
    #   {:ok, funding_rates}
    # end

    {:ok, []}
  end

  # @date_format "{ISO:Extended}"

  # defp build(venue_funding_rate, venue_id) do
  #   venue_product_symbol = venue_funding_rate.future
  #   product_symbol = venue_product_symbol |> Ftx.Products.to_symbol()
  #   next_time = Timex.parse!(venue_funding_rate.next_funding_time, @date_format)
  #   next_rate = Tai.Utils.Decimal.cast!(venue_funding_rate.next_funding_rate, :normalize)

  #   %Tai.Venues.EstimatedFundingRate{
  #     venue: venue_id,
  #     venue_product_symbol: venue_product_symbol,
  #     product_symbol: product_symbol,
  #     next_time: next_time,
  #     next_rate: next_rate
  #   }
  # end
end
