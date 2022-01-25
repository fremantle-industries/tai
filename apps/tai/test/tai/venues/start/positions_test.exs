defmodule Tai.Venues.Start.PositionsTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule VenueAdapter do
    use Support.StartVenueAdapter

    def accounts(venue_id, credential_id, _credentials) do
      account_a = build_account(venue_id, credential_id, :btc)
      account_b = build_account(venue_id, credential_id, :eth)
      {:ok, [account_a, account_b]}
    end

    def positions(venue_id, credential_id, _credentials) do
      position_a = build_position(venue_id, credential_id, :btc_usdt)
      position_b = build_position(venue_id, credential_id, :eth_usdt)
      {:ok, [position_a, position_b]}
    end

    defp build_account(venue_id, credential_id, asset) do
      struct(
        Tai.Venues.Account,
        venue_id: venue_id,
        credential_id: credential_id,
        asset: asset
      )
    end

    defp build_position(venue_id, credential_id, symbol) do
      struct(
        Tai.Trading.Position,
        venue_id: venue_id,
        credential_id: credential_id,
        symbol: symbol
      )
    end
  end

  defmodule MaintenanceErrorAdapter do
    use Support.StartVenueAdapter

    def accounts(venue_id, credential_id, _credentials) do
      account_a = build_account(venue_id, credential_id, :btc)
      account_b = build_account(venue_id, credential_id, :eth)
      {:ok, [account_a, account_b]}
    end

    def positions(_venue_id, _credential_id, _credentials) do
      {:error, :maintenance}
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

  defmodule NotSupportedAdapter do
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

    def positions(_venue_id, _credential_id, _credentials) do
      {:error, :not_supported}
    end
  end

  defmodule RaiseErrorAdapter do
    use Support.StartVenueAdapter

    def positions(_venue_id, _credential_id, _credentials) do
      raise "raise_error_for_positions"
    end
  end

  @base_venue struct(
                Tai.Venue,
                adapter: TestAdapter,
                id: :venue_a,
                credentials: %{main: %{}},
                accounts: "*",
                products: "*",
                market_streams: "*",
                timeout: 1_000
              )

  test "broadcasts a summary event with the total positions" do
    venue = @base_venue |> Map.put(:adapter, VenueAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.HydratePositions{} = event, :info)
    assert event.venue_id == venue.id
    assert event.total == 2
  end

  test "broadcasts a summary event with a 0 positions when not supported" do
    venue = @base_venue |> Map.put(:adapter, NotSupportedAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.HydratePositions{} = event, :info)
    assert event.venue_id == venue.id
    assert event.total == 0
  end

  test "broadcasts a start error event when the adapter returns an error" do
    venue = @base_venue |> Map.put(:adapter, MaintenanceErrorAdapter)
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert event.reason == [positions: [main: :maintenance]]
  end

  test "broadcasts a start error event when the adapter raises an error" do
    venue = @base_venue |> Map.put(:adapter, RaiseErrorAdapter)
    Tai.SystemBus.subscribe({:venue, :start_error})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, venue})

    assert_receive {{:venue, :start_error}, start_error_venue, start_error_reasons}
    assert start_error_venue == @base_venue.id
    assert [positions: _] = start_error_reasons

    assert_event(%Tai.Events.VenueStartError{} = event, :error)
    assert event.venue == venue.id
    assert [positions: position_errors] = event.reason
    assert Enum.count(position_errors) == 1
    assert [{_, {error, stacktrace}} | _] = position_errors
    assert error == %RuntimeError{message: "raise_error_for_positions"}
    assert Enum.count(stacktrace) > 0
  end
end
