defmodule Tai.Venues.Adapters.AccountsTest do
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

  Tai.TestSupport.Helpers.test_venue_adapters_accounts()
  |> Enum.map(fn venue ->
    @venue venue
    @credential_id venue.credentials |> Map.keys() |> List.first()

    test "#{venue.id} returns a list of accounts" do
      setup_venue(@venue.id)

      use_cassette "venue_adapters/shared/accounts/#{@venue.id}/success" do
        assert {:ok, accounts} = Tai.Venues.Client.accounts(@venue, @credential_id)
        assert Enum.count(accounts) > 0
        assert [%Tai.Venues.Account{} = account | _] = accounts
        assert account.venue_id == @venue.id
        assert account.credential_id == @credential_id
        assert Decimal.compare(account.equity, Decimal.new(0)) != :lt
        assert Decimal.compare(account.free, Decimal.new(0)) != :lt
        assert Decimal.compare(account.locked, Decimal.new(0)) != :lt
      end
    end
  end)

  def setup_venue(:mock) do
    Tai.TestSupport.Mocks.Responses.Accounts.for_venue_and_credential(
      :mock,
      :main,
      [
        %{
          asset: :btc,
          equity: Decimal.new("0.3"),
          free: Decimal.new("0.1"),
          locked: Decimal.new("0.2")
        },
        %{
          asset: :ltc,
          equity: Decimal.new("0.7"),
          free: Decimal.new("0.3"),
          locked: Decimal.new("0.4")
        }
      ]
    )
  end

  def setup_venue(_), do: nil
end
