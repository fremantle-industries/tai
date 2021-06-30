defmodule Examples.PingPong.CreateExitOrderTest do
  use Tai.TestSupport.DataCase, async: false
  alias Examples.PingPong.CreateExitOrder

  @advisor_id __MODULE__

  test ".create/4 enqueues an exit order for the newly filled qty" do
    Process.register(self(), @advisor_id)
    prev_order = build_order(cumulative_qty: Decimal.new(2))
    updated_order = build_order(price: Decimal.new(100), cumulative_qty: Decimal.new(8))
    product = struct(Tai.Venues.Product, price_increment: Decimal.new("0.5"))
    config = struct(Examples.PingPong.Config, product: product)

    assert {:ok, exit_order} =
             CreateExitOrder.create(@advisor_id, prev_order, updated_order, config)

    assert exit_order.status == :enqueued
    assert exit_order.price == Decimal.new("100.5")
    assert exit_order.qty == Decimal.new(6)
  end

  @base_attrs [
    venue: "venue_a",
    credential: "credential_a",
    product_symbol: "btc_usd",
    venue_product_symbol: "BTC-USD",
    product_type: :spot
  ]
  defp build_order(attrs) do
    merged_attrs = Keyword.merge(@base_attrs, attrs)
    struct(Tai.NewOrders.Order, merged_attrs)
  end
end
