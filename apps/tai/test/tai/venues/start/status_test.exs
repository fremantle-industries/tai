defmodule Tai.Venues.Start.StatusTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule TestAdapter do
    use Support.StartVenueAdapter
  end

  @venue struct(
           Tai.Venue,
           adapter: TestAdapter,
           id: :venue_a,
           credentials: %{},
           accounts: "*",
           products: "*",
           timeout: 1_000
         )

  setup do
    start_supervised!({TaiEvents, 1})
    start_supervised!(Tai.Venues.ProductStore)
    start_supervised!(Tai.Venues.AccountStore)
    start_supervised!(Tai.Venues.FeeStore)
    start_supervised!(Tai.Trading.PositionStore)
    start_supervised!(Tai.Venues.StreamsSupervisor)
    :ok
  end

  test "returns the current status" do
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, @venue})

    assert_event(%Tai.Events.VenueStart{} , :info)
    assert Tai.Venues.Start.status(@venue.id) == :success
  end
end
