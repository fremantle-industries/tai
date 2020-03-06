defmodule ExamplesSupport.E2E.LogSpread do
  alias Tai.TestSupport.Mocks
  import Tai.TestSupport.Mock

  @venue :test_exchange_a
  @product_symbol :btc_usd

  def seed_mock_responses(:log_spread) do
    Mocks.Responses.Products.for_venue(
      @venue,
      [
        %{symbol: @product_symbol},
        %{symbol: :ltc_usd}
      ]
    )
  end

  def seed_venues(:log_spread) do
    {:ok, _} =
      Tai.Venue
      |> struct(
        id: @venue,
        adapter: Tai.VenueAdapters.Mock,
        credentials: %{},
        accounts: "*",
        products: "*",
        quote_depth: 1,
        timeout: 1000
      )
      |> Tai.Venues.VenueStore.put()
  end

  def push_stream_market_data({:log_spread, :snapshot, venue_id, product_symbol})
      when venue_id == @venue and product_symbol == @product_symbol do
    push_market_data_snapshot(
      %Tai.Markets.Location{
        venue_id: @venue,
        product_symbol: @product_symbol
      },
      %{6500.1 => 1.1},
      %{6500.11 => 1.2}
    )
  end

  def advisor_group_config(:log_spread) do
    [
      advisor: Examples.LogSpread.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      products: "*"
    ]
  end
end
