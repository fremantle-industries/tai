defmodule Tai.Venues.Adapters.AccountsErrorTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
    :ok
  end

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  Tai.TestSupport.Helpers.test_venue_adapters_accounts_error()
  |> Enum.map(fn venue ->
    @venue venue
    @credential_id :error

    test "#{venue.id} returns an error with the reason" do
      use_cassette "venue_adapters/shared/accounts/#{@venue.id}/error" do
        assert {:error, reason} = Tai.Venues.Client.accounts(@venue, @credential_id)
        assert reason != nil
      end
    end
  end)
end
