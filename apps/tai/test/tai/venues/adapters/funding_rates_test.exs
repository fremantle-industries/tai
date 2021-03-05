defmodule Tai.Venues.Adapters.FundingRatesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters_funding_rates()

  @test_venues
  |> Enum.map(fn venue ->
    @venue venue

    test "#{venue.id} retrieves the product information for the exchange" do
      setup_adapter(@venue.id)

      use_cassette "venue_adapters/shared/funding_rates/#{@venue.id}/success" do
        assert {:ok, funding_rates} = Tai.Venues.Client.funding_rates(@venue)
        assert Enum.count(funding_rates) > 0
        assert [%Tai.Venues.FundingRate{} = funding_rate | _] = funding_rates
        assert funding_rate.venue == @venue.id
        assert funding_rate.venue_product_symbol != nil
        assert funding_rate.product_symbol != nil
        assert %DateTime{} = funding_rate.time
        assert %Decimal{} = funding_rate.rate
      end
    end
  end)

  def setup_adapter(:mock) do
    now = Timex.now
    Tai.TestSupport.Mocks.Responses.FundingRates.for_venue(
      :mock,
      [
        %{
          venue_product_symbol: "BTC-USD",
          product_symbol: :btc_usd,
          time: now,
          rate: Decimal.new("0.001")
        },
        %{
          venue_product_symbol: "LTC-USD",
          product_symbol: :ltc_usd,
          time: now,
          rate: Decimal.new("0.002")
        }
      ]
    )
  end

  def setup_adapter(_), do: nil
end
