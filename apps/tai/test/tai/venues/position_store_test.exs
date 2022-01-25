defmodule Tai.Venues.PositionStoreTest do
  use Tai.TestSupport.DataCase, async: false

  @venue :venue_a

  test "broadcasts a message after the record is stored" do
    :ok = Tai.SystemBus.subscribe(:position_store)
    position = struct(Tai.Trading.Position, venue_id: @venue)

    assert {:ok, _} = Tai.Trading.PositionStore.put(position)
    assert_receive {:position_store, :after_put, stored_position}

    positions = Tai.Trading.PositionStore.all()
    assert Enum.count(positions) == 1
    assert Enum.member?(positions, position)
    assert stored_position == position
  end
end
