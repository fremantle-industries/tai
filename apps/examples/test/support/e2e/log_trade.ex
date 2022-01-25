defmodule ExamplesSupport.E2E.LogTrade do
  alias Tai.TestSupport.Mocks

  @venue :test_exchange_a
  @product_symbol :btc_usd

  def seed_mock_responses(:log_trade) do
    Mocks.Responses.Products.for_venue(
      @venue,
      [
        %{symbol: @product_symbol},
        %{symbol: :ltc_usd}
      ]
    )
  end

  def seed_venues(:log_trade) do
    {:ok, _} =
      Tai.Venue
      |> struct(
        id: @venue,
        adapter: Tai.VenueAdapters.Mock,
        credentials: %{},
        accounts: "*",
        products: "*",
        market_streams: "*",
        quote_depth: 1,
        timeout: 1000
      )
      |> Tai.Venues.VenueStore.put()
  end

  def push_stream_trade({:log_trade, :trade, venue_id, product_symbol})
      when venue_id == @venue and product_symbol == @product_symbol do
    Tai.TestSupport.Mock.push_trade(%Tai.Markets.Trade{
      id: Ecto.UUID.generate(),
      venue: venue_id,
      product_symbol: product_symbol,
      price: "100.1",
      qty: "7.0",
      side: "buy",
      liquidation: false,
      received_at: nil,
      venue_timestamp: DateTime.utc_now()
    })
  end

  def fleet_config(:log_trade) do
    %{
      advisor: Examples.LogTrade.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      market_streams: "*"
    }
  end
end
