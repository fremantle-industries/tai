defmodule Tai.TestSupport.Mocks.Responses.EstimatedFundingRates do
  def for_venue(venue_id, estimated_funding_rates_attrs) do
    estimated_funding_rates =
      estimated_funding_rates_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.EstimatedFundingRate,
          Map.merge(%{venue: venue_id}, attrs)
        )
      end)

    {:estimated_funding_rates, venue_id}
    |> Tai.TestSupport.Mocks.Server.insert(estimated_funding_rates)
  end
end
