defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.NoOpTablesTest do
  use Tai.TestSupport.DataCase, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @venue :my_venue
  @credential :main
  @received_at Tai.Time.monotonic_time()

  setup do
    TaiEvents.firehose_subscribe()
    pid = start_supervised!({ProcessAuth, [venue: @venue, credential: {@credential, %{}}]})
    {:ok, %{pid: pid}}
  end

  test "ignores messages for the 'transact' table", %{pid: pid} do
    cast_noop_msg("transact")

    refute_event(%Tai.Events.StreamMessageUnhandled{}, :warning)
    assert Process.alive?(pid) == true
  end

  test "ignores messages for the 'execution' table", %{pid: pid} do
    cast_noop_msg("execution")

    refute_event(%Tai.Events.StreamMessageUnhandled{}, :warning)
    assert Process.alive?(pid) == true
  end

  test "ignores messages for the 'wallet' table", %{pid: pid} do
    cast_noop_msg("wallet")

    refute_event(%Tai.Events.StreamMessageUnhandled{}, :warning)
    assert Process.alive?(pid) == true
  end

  defp cast_noop_msg(table) do
    msg = %{"table" => table}

    @venue
    |> ProcessAuth.process_name()
    |> GenServer.cast({msg, @received_at})
  end
end
