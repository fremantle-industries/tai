defmodule Tai.Venues.Start.ErrorFromTimeoutTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event

  defmodule TimeoutVenueAdapter do
    use Support.StartVenueAdapter

    def products(_venue_id) do
      :timer.sleep(2)
      {:ok, []}
    end
  end

  @venue struct(
           Tai.Venue,
           adapter: TimeoutVenueAdapter,
           id: :venue_a,
           credentials: %{},
           accounts: "*",
           products: "*",
           timeout: 1
         )

  test "broadcasts an error when the venue hasn't started within the timeout" do
    Tai.SystemBus.subscribe({:venue, :start_error})
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, @venue})

    assert_receive {{:venue, :start_error}, start_error_venue, start_error_reason}
    assert start_error_venue == @venue.id
    assert start_error_reason == :timeout

    assert_event(%Tai.Events.VenueStartError{} = start_event, :error)
    assert start_event.venue == @venue.id
    assert start_event.reason == :timeout

    refute_event(%Tai.Events.VenueStart{})
  end
end
