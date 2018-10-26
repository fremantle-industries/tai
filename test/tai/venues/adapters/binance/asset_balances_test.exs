defmodule Tai.VenueAdapters.Binance.AssetBalancesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  setup_all do
    HTTPoison.start()
    adapter = find_adapter(@test_adapters, :binance)
    {:ok, %{adapter: adapter}}
  end

  test "returns an error tuple when the secret is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/binance/error_invalid_secret" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.CredentialError{reason: "API-key format invalid."}
             }
    end
  end

  test "returns an error tuple when the api key is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/binance/error_invalid_api_key" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.CredentialError{reason: "API-key format invalid."}
             }
    end
  end

  test "returns an error tuple when the request times out", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/binance/error_timeout" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.TimeoutError{reason: "network request timed out"}
             }
    end
  end

  test "returns an error tuple when the timestamp of the local machine is outside the Binance receive window",
       %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/binance/error_timestamp_outside_recv_window" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.ApiError{reason: "Timestamp for this request is outside of the recvWindow."}
             }
    end
  end

  def find_adapter(adapters, exchange_id) do
    Enum.find(adapters, &(&1.id == exchange_id))
  end
end
