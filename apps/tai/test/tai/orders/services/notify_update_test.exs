defmodule Tai.Orders.Services.NotifyUpdateTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.Orders.Order

  setup do
    start_supervised!({TaiEvents, 1})
    :ok
  end

  describe ".notify!" do
    test "broadcasts an order update event" do
      TaiEvents.firehose_subscribe()
      updated_order = struct(Order, client_id: "abc123")

      Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order)

      assert_event(%Tai.Events.OrderUpdated{} = event)
      assert event.client_id == updated_order.client_id
    end

    test "executes the callback when it's a function" do
      callback = &send(self(), {:callback_executed, &1, &2})
      updated_order = struct(Order, order_updated_callback: callback)

      Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order)

      assert_receive {:callback_executed, prev, updated}
      assert prev == nil
      assert updated == updated_order
    end

    test "sends a message when the callback is a pid" do
      updated_order = struct(Order, order_updated_callback: self())

      Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order)

      assert_receive {:order_updated, prev, updated}
      assert prev == nil
      assert updated == updated_order
    end

    test "sends a message when the callback is an atom" do
      name = __MODULE__
      Process.register(self(), name)
      updated_order = struct(Order, order_updated_callback: name)

      Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order)

      assert_receive {:order_updated, prev, updated}
      assert prev == nil
      assert updated == updated_order
    end

    test "sends a message with data when the callback is a pid tuple with data" do
      updated_order = struct(Order, order_updated_callback: {self(), :data})

      Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order)

      assert_receive {:order_updated, prev, updated, data}
      assert prev == nil
      assert updated == updated_order
      assert data == :data
    end

    test "sends a message with data when the callback is an atom tuple with data" do
      name = __MODULE__
      Process.register(self(), name)
      updated_order = struct(Order, order_updated_callback: {name, :data})

      Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order)

      assert_receive {:order_updated, prev, updated, data}
      assert prev == nil
      assert updated == updated_order
      assert data == :data
    end

    test "returns an error when sending a message to a process that doesn't exist" do
      updated_order = struct(Order, order_updated_callback: :dead_process)

      assert Tai.Orders.Services.NotifyUpdate.notify!(nil, updated_order) == {:error, :noproc}
    end
  end
end
