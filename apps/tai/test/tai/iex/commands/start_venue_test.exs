defmodule Tai.IEx.Commands.StartVenueTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  import ExUnit.CaptureIO

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

    {:ok, _} =
      Tai.Venue
      |> struct(
        id: @venue,
        adapter: StartVenueAdapter,
        credentials: %{},
        accounts: "*",
        products: "*",
        timeout: 1_000
      )
      |> Tai.Venues.VenueStore.put()

    :ok
  end

  test "shows a message that the venue is starting" do
    TaiEvents.firehose_subscribe()

    assert capture_io(fn -> Tai.IEx.start_venue(@venue) end) == """
           starting...
           """

    assert_event(%Tai.Events.VenueStart{} = event)
    assert event.venue == @venue
  end

  test "shows an error when the venue doesn't exist" do
    TaiEvents.firehose_subscribe()

    assert capture_io(fn -> Tai.IEx.start_venue(:i_dont_exist) end) ==
             """
             error: :i_dont_exist was not found
             """

    refute_event(%Tai.Events.VenueStartError{})
  end

  test "shows an error when the venue is already started" do
    TaiEvents.firehose_subscribe()

    capture_io(fn -> Tai.IEx.start_venue(@venue) end)
    assert_event(%Tai.Events.VenueStart{})

    assert capture_io(fn -> Tai.IEx.start_venue(@venue) end) ==
             """
             error: :venue_b is already started
             """

    refute_event(%Tai.Events.VenueStart{})
  end
end
