defmodule Tai.TestSupport.Mocks.Responses.FundingRates do
  def for_venue(venue_id, funding_rates_attrs) do
    funding_rates =
      funding_rates_attrs
      |> Enum.map(fn attrs ->
        struct(
          Tai.Venues.FundingRate,
          Map.merge(%{venue: venue_id}, attrs)
        )
      end)

    {:funding_rates, venue_id}
    |> Tai.TestSupport.Mocks.Server.insert(funding_rates)
  end
end
