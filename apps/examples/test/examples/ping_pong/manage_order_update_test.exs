defmodule Examples.PingPong.ManageOrderUpdateTest do
  use ExUnit.Case, async: true
  alias Examples.PingPong.ManageOrderUpdate

  defmodule TestOrderProvider do
    def create_exit_order(_advisor_id, _prev_entry_order, _updated_entry_order, _config) do
      exit_order = struct(Tai.Trading.Order, client_id: "exitOrderA", status: :enqueued)

      {:ok, exit_order}
    end
  end

  describe ".entry_order_updated/4" do
    test "creates an exit order for each partial fill" do
      product = struct(Tai.Venues.Product, price_increment: Decimal.new("0.5"))
      config = struct(Examples.PingPong.Config, product: product)

      prev_entry_order =
        struct(Tai.Trading.Order, status: :partially_filled, price: Decimal.new(100))

      updated_entry_order =
        struct(Tai.Trading.Order, status: :partially_filled, price: Decimal.new(100))

      run_store = %{entry_order: updated_entry_order}
      state = struct(Tai.Advisor.State, config: config, store: run_store)

      assert {:ok, updated_run_store} =
               ManageOrderUpdate.entry_order_updated(
                 run_store,
                 prev_entry_order,
                 state,
                 TestOrderProvider
               )

      assert %Tai.Trading.Order{} = updated_run_store.exit_order
      assert updated_run_store.exit_order.status == :enqueued
    end
  end
end
