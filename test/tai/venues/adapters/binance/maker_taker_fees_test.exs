defmodule Tai.VenueAdapters.Binance.MakerTakerFeesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = @test_adapters |> Map.fetch!(:binance)
    {:ok, %{adapter: adapter}}
  end

  test "returns an error tuple when the secret is invalid", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/maker_taker_fees/binance/error_invalid_secret" do
      assert {:error, {:credentials, reason}} = Tai.Venue.maker_taker_fees(adapter, :main)
      assert reason == "API-key format invalid."
    end
  end

  test "returns an error tuple when the api key is invalid", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/maker_taker_fees/binance/error_invalid_api_key" do
      assert {:error, {:credentials, reason}} = Tai.Venue.maker_taker_fees(adapter, :main)
      assert reason == "API-key format invalid."
    end
  end

  test "returns an error tuple when the request times out", %{adapter: adapter} do
    use_cassette "venue_adapters/shared/maker_taker_fees/binance/error_timeout" do
      assert Tai.Venue.maker_taker_fees(adapter, :main) == {:error, :timeout}
    end
  end

  test "returns an error tuple when the timestamp of the local machine is outside the Binance receive window",
       %{adapter: adapter} do
    use_cassette "venue_adapters/shared/maker_taker_fees/binance/error_timestamp_outside_recv_window" do
      assert Tai.Venue.maker_taker_fees(adapter, :main) == {
               :error,
               "Timestamp for this request is outside of the recvWindow."
             }
    end
  end
end
