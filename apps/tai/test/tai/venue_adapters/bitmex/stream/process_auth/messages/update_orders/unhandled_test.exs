defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.UnhandledTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  test ".process/3 broadcasts an unhandled message warning" do
    msg = struct(ProcessAuth.Messages.UpdateOrders.Unhandled, data: "my-msg")
    received_at = Tai.Time.monotonic_time()
    state = struct(ProcessAuth.State, venue: :my_venue)
    TaiEvents.firehose_subscribe()

    ProcessAuth.Message.process(msg, received_at, state)

    assert_event(%Tai.Events.StreamMessageUnhandled{} = unhandled_event)
    assert unhandled_event.venue_id == :my_venue
    assert %DateTime{} = unhandled_event.received_at
    assert unhandled_event.msg == "my-msg"
  end
end
