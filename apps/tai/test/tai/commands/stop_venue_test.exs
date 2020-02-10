defmodule Tai.Commands.StopVenueTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  import Tai.TestSupport.Assertions.Event
  import Tai.TestSupport.Mock

  @venue :venue_b

  defmodule StartVenueAdapter do
    use Support.StartVenueAdapter
  end

  setup do
    start_supervised!(Tai.TestSupport.Mocks.Server)
    start_supervised!({TaiEvents, 1})
    start_supervised!(Tai.Venues.VenueStore)
    start_supervised!(Tai.Venues.StreamsSupervisor)
    start_supervised!(Tai.Venues.Supervisor)

    mock_venue(
      id: @venue,
      adapter: StartVenueAdapter,
      credentials: %{},
      accounts: "*",
      products: "*",
      timeout: 1_000
    )

    :ok
  end

  test "stops a running venue" do
    TaiEvents.firehose_subscribe()

    capture_io(fn -> Tai.CommandsHelper.start_venue(@venue) end)
    assert_event(%Tai.Events.VenueStart{})

    assert capture_io(fn -> Tai.CommandsHelper.stop_venue(@venue) end) == """
           stopped successfully
           """
  end

  test "shows an error when the venue doesn't exist" do
    TaiEvents.firehose_subscribe()

    assert capture_io(fn -> Tai.CommandsHelper.stop_venue(:i_dont_exist) end) ==
             """
             error: :i_dont_exist was not found
             """

    refute_event(%Tai.Events.VenueStartError{})
  end

  test "shows an error when the venue is already stopped" do
    TaiEvents.firehose_subscribe()

    assert capture_io(fn -> Tai.CommandsHelper.stop_venue(@venue) end) ==
             """
             error: :venue_b is already stopped
             """
  end
end
