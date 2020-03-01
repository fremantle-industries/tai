defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.OrderTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tzdata)
    end)

    {:ok, _} = Application.ensure_all_started(:tzdata)
    start_supervised!({TaiEvents, 1})
    start_supervised!(Tai.Trading.OrderStore)
    start_supervised!({ProcessAuth, [venue_id: :my_venue]})
    :ok
  end

  test "processes each venue message" do
    TaiEvents.firehose_subscribe()
    bitmex_orders = [%{"unhandled" => true}]

    :my_venue
    |> ProcessAuth.to_name()
    |> GenServer.cast(
      {%{"table" => "order", "action" => "update", "data" => bitmex_orders}, :ignore}
    )

    assert_event(%Tai.Events.StreamMessageUnhandled{} = not_found_event)
  end
end
