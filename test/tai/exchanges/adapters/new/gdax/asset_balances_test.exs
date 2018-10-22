defmodule Tai.ExchangeAdapters.New.Gdax.AssetBalancesTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @test_adapters Tai.TestSupport.Helpers.test_exchange_adapters()

  setup_all do
    HTTPoison.start()
    adapter = find_adapter(@test_adapters, :gdax)
    {:ok, %{adapter: adapter}}
  end

  test "returns an error tuple when the passphrase is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/gdax/error_invalid_passphrase" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.CredentialError{reason: "Invalid Passphrase"}
             }
    end
  end

  test "returns an error tuple when the api key is invalid", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/gdax/error_invalid_api_key" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.CredentialError{reason: "Invalid API Key"}
             }
    end
  end

  test "returns an error tuple when down for maintenance", %{adapter: adapter} do
    use_cassette "exchange_adapters/shared/asset_balances/gdax/error_maintenance" do
      assert Tai.Exchanges.Exchange.asset_balances(adapter, :main) == {
               :error,
               %Tai.ServiceUnavailableError{
                 reason:
                   "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"
               }
             }
    end
  end

  def find_adapter(adapters, exchange_id) do
    Enum.find(adapters, &(&1.id == exchange_id))
  end
end
