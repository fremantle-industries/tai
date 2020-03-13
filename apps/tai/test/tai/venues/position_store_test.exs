defmodule Tai.Venues.PositionStoreTest do
  use ExUnit.Case, async: false

  @test_store_id __MODULE__
  @venue :venue_a

  setup do
    start_supervised!({Tai.SystemBus, 1})
    start_supervised!({Tai.Trading.PositionStore, id: @test_store_id})

    :ok
  end

  test "broadcasts a message after the record is stored" do
    Tai.SystemBus.subscribe(:position_store)
    position = struct(Tai.Trading.Position, venue_id: @venue)

    assert {:ok, _} = Tai.Trading.PositionStore.put(position, @test_store_id)
    assert_receive {:position_store, :after_put, stored_position}

    positions = Tai.Trading.PositionStore.all(@test_store_id)
    assert Enum.count(positions) == 1
    assert Enum.member?(positions, position)
    assert stored_position == position
  end
end
