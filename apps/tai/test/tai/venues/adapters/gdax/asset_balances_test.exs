defmodule Tai.Venues.Adapters.Gdax.AssetBalancesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_venues Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    venue = @test_venues |> Map.fetch!(:gdax)
    {:ok, %{venue: venue}}
  end

  test "returns an error tuple when the passphrase is invalid", %{venue: venue} do
    use_cassette "venue_adapters/shared/asset_balances/gdax/error_invalid_passphrase" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.asset_balances(venue, :main)
      assert reason == "Invalid Passphrase"
    end
  end

  test "returns an error tuple when the api key is invalid", %{venue: venue} do
    use_cassette "venue_adapters/shared/asset_balances/gdax/error_invalid_api_key" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.asset_balances(venue, :main)
      assert reason == "Invalid API Key"
    end
  end

  test "returns an error tuple when down for maintenance", %{venue: venue} do
    use_cassette "venue_adapters/shared/asset_balances/gdax/error_maintenance" do
      assert {:error, reason} = Tai.Venues.Client.asset_balances(venue, :main)

      assert reason ==
               {:service_unavailable,
                "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"}
    end
  end
end
