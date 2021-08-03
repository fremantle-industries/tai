defmodule Tai.Venues.Start.StatusTest do
  use Tai.TestSupport.DataCase, async: false
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
           order_books: "*",
           timeout: 1_000
         )

  test "returns the current status" do
    TaiEvents.firehose_subscribe()

    start_supervised!({Tai.Venues.Start, @venue})

    assert_event(%Tai.Events.VenueStart{} , :info)
    assert Tai.Venues.Start.status(@venue.id) == :success
  end
end
