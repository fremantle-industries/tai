defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.UnhandledTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth
  alias Tai.Events

  setup do
    start_supervised!({Tai.Events, 1})
    :ok
  end

  test ".process/3 broadcasts an unhandled message warning" do
    msg = struct(ProcessAuth.Messages.UpdateOrders.Unhandled, data: "my-msg")
    received_at = Timex.now()
    state = struct(ProcessAuth.State, venue_id: :my_venue)
    Events.firehose_subscribe()

    ProcessAuth.Message.process(msg, received_at, state)

    assert_event(%Events.StreamMessageUnhandled{} = unhandled_event)
    assert unhandled_event.venue_id == :my_venue
    assert unhandled_event.received_at == received_at
    assert unhandled_event.msg == "my-msg"
  end
end
