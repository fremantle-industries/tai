defmodule Tai.Venues.Adapters.AmendBulkOrderTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.Orders.Responses

  setup_all do
    HTTPoison.start()
  end

  Tai.TestSupport.Helpers.test_venue_adapters_amend_bulk_order_accepted()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} can change price and qty" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_price = amend_price(@venue.id, enqueued_order.side)
      amend_qty = amend_qty(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, price: amend_price, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_bulk_price_and_qty_ok" do
        assert {:ok, create_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, create_response)

        assert {:ok, amend_bulk_response} =
                 Tai.Venues.Client.amend_bulk_orders([{open_order, attrs}])

        assert Enum.count(amend_bulk_response.orders) == 1
        amend_response = Enum.at(amend_bulk_response.orders, 0)
        assert %Responses.AmendAccepted{} = amend_response
        assert amend_response.id == open_order.venue_order_id
        assert amend_response.received_at != nil
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end
  end)

  defp build_enqueued_order(venue_id, side) do
    venue = venue_id |> Atom.to_string()

    struct(Tai.Orders.Order, %{
      client_id: Ecto.UUID.generate(),
      venue: venue,
      credential: "main",
      product_symbol: venue |> product_symbol,
      side: side,
      price: venue |> price(side),
      qty: venue |> qty(side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp build_open_order(order, amend_response) do
    struct(Tai.Orders.Order, %{
      venue_order_id: amend_response.id,
      venue: order.venue,
      credential: "main",
      symbol: order.venue |> product_symbol,
      side: order.side,
      price: order.venue |> price(order.side),
      qty: order.venue |> qty(order.side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol("bitmex"), do: "xbtusd"
  defp product_symbol(_), do: "btc_usd"

  defp price("bitmex", :buy), do: Decimal.new("2001.5")

  defp qty("bitmex", _), do: Decimal.new(2)

  defp amend_price(:bitmex, :buy), do: Decimal.new("2300.5")

  defp amend_qty(:bitmex, :buy), do: Decimal.new(10)

  defp amend_attrs(:bitmex, price: price, qty: qty), do: %{price: price, qty: qty}
  defp amend_attrs(:bitmex, price: price), do: %{price: price}
  defp amend_attrs(:bitmex, qty: qty), do: %{qty: qty}
end
