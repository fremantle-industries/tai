defmodule Tai.Venues.StatusTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule VenueAdapter do
    use Support.StartVenueAdapter
  end

  defmodule ErrorVenueAdapter do
    use Support.StartVenueAdapter

    def products(_) do
      raise "products error"
    end
  end

  @venue struct(
           Tai.Venue,
           id: :status_venue,
           adapter: VenueAdapter,
           credentials: %{main: %{}},
           accounts: "*",
           products: "*",
           timeout: 100
         )

  test ".status/1 is :stopped when there is no start process or stream" do
    assert Tai.Venues.Status.status(@venue) == :stopped
  end

  test ".status/1 is :starting when there is a start process but no stream" do
    start_supervised!({Tai.Venues.Start, @venue})
    assert Tai.Venues.Status.status(@venue) == :starting
  end

  test ".status/1 is :running when there is a stream" do
    stream = struct(Tai.Venues.Stream, venue: @venue)
    Tai.Venues.StreamsSupervisor.start(stream)
    assert Tai.Venues.Status.status(@venue) == :running
  end

  test ".status/1 is :error when the venue could not be started" do
    TaiEvents.firehose_subscribe()

    venue = Map.merge(@venue, %{adapter: ErrorVenueAdapter})
    start_supervised!({Tai.Venues.Start, venue})

    assert_event(%Tai.Events.VenueStartError{} , :error)
    assert Tai.Venues.Status.status(venue) == :error
  end
end
