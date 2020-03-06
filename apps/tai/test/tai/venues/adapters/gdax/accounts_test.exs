defmodule Tai.Venues.Adapters.Gdax.AccountsTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  @venue Tai.TestSupport.Helpers.test_venue_adapter(:gdax)

  setup_all do
    HTTPoison.start()
    :ok
  end

  test "returns an error tuple when the passphrase is invalid" do
    use_cassette "venue_adapters/shared/accounts/gdax/error_invalid_passphrase" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.accounts(@venue, :main)
      assert reason == "Invalid Passphrase"
    end
  end

  test "returns an error tuple when the api key is invalid" do
    use_cassette "venue_adapters/shared/accounts/gdax/error_invalid_api_key" do
      assert {:error, {:credentials, reason}} = Tai.Venues.Client.accounts(@venue, :main)
      assert reason == "Invalid API Key"
    end
  end

  test "returns an error tuple when down for maintenance" do
    use_cassette "venue_adapters/shared/accounts/gdax/error_maintenance" do
      assert {:error, reason} = Tai.Venues.Client.accounts(@venue, :main)

      assert {:service_unavailable, msg} = reason

      assert msg ==
               "GDAX is currently under maintenance. For updates please see https://status.gdax.com/"
    end
  end
end
