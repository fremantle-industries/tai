defmodule Tai.Venues.Start.AccountsTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule TestAdapter do
    use Support.StartVenueAdapter

    def accounts(venue_id, credential_id, _credentials) do
      account_a = build_account(venue_id, credential_id, :btc)
      account_b = build_account(venue_id, credential_id, :eth)

      {:ok, [account_a, account_b]}
    end

    defp build_account(venue_id, credential_id, asset) do
      struct(
        Tai.Venues.Account,
        venue_id: venue_id,
        credential_id: credential_id,
        asset: asset
      )
    end
  end

  defmodule MaintenanceErrorAdapter do
    use Support.StartVenueAdapter

    def accounts(_venue_id, _credential_id, _credentials) do
      {:error, :maintenance}
    end
  end

  defmodule RaiseErrorAdapter do
    use Support.StartVenueAdapter

    def accounts(_venue_id, _credential_id, _credentials) do
      raise "raise_error_for_accounts"
    end
  end

  defmodule VenueAccounts do
    def filter(products) do
      Enum.filter(products, &(&1.credential_id == :main_a && &1.asset == :btc))
    end
  end

  @base_venue struct(
                Tai.Venue,
                adapter: TestAdapter,
                id: :venue_a,
                credentials: %{main_a: %{}, main_b: %{}},
                accounts: "*",
                products: "*",
                market_streams: "*",
                timeout: 1_000
              )

  test "can filter accounts with a juice query" do
    venue = @base_venue |> Map.put(:accounts, "eth")
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})
    assert_event(%Tai.Events.VenueStart{}, :info)

    accounts = Tai.Venues.AccountStore.all()
    assert Enum.count(accounts) == 2

    assets = Enum.map(accounts, & &1.asset)
    assert Enum.all?(assets, &(&1 == :eth))
  end

  test "can filter accounts with a module function" do
    venue = @base_venue |> Map.put(:accounts, {VenueAccounts, :filter})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})
    assert_event(%Tai.Events.VenueStart{}, :info)

    accounts = Tai.Venues.AccountStore.all()
    assert Enum.count(accounts) == 1
    assert Enum.at(accounts, 0).asset == :btc
    assert Enum.at(accounts, 0).credential_id == :main_a
  end

  test "broadcasts a summary event" do
    venue = @base_venue |> Map.put(:accounts, {VenueAccounts, :filter})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.HydrateAccounts{} = event, :info)
    assert event.venue_id == venue.id
    assert event.total == 4
    assert event.filtered == 1
  end

  test "broadcasts a start error event when the adapter returns an error" do
    venue = @base_venue |> Map.put(:adapter, MaintenanceErrorAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert event.reason == [accounts: [main_a: :maintenance, main_b: :maintenance]]
  end

  test "broadcasts a start error event when the adapter raises an error" do
    venue = @base_venue |> Map.put(:adapter, RaiseErrorAdapter)
    Tai.SystemBus.subscribe({:venue, :start_error})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_receive {{:venue, :start_error}, start_error_venue, start_error_reasons}
    assert start_error_venue == @base_venue.id
    assert [accounts: _] = start_error_reasons

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert [accounts: account_errors] = event.reason
    assert Enum.count(account_errors) == 2
    assert [{_, {error, stacktrace}} | _] = account_errors
    assert error == %RuntimeError{message: "raise_error_for_accounts"}
    assert Enum.count(stacktrace) > 0
  end
end
