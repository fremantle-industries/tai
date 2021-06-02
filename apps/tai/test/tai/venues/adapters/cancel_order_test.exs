defmodule Tai.Venues.Adapters.CancelOrderTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.NewOrders

  setup_all do
    HTTPoison.start()
  end

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_accepted()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} returns an order response with a canceled status & final quantities" do
      enqueued_order = build_enqueued_order(@venue.id)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_ok" do
        assert {:ok, order_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:ok, order_response} = Tai.Venues.Client.cancel_order(open_order)
        assert %NewOrders.Responses.CancelAccepted{} = order_response
        assert order_response.id != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id) do
    venue = venue_id |> Atom.to_string()

    struct(NewOrders.Order, %{
      client_id: "f5559e85-7a3c-4c07-94d8-5e7a74079733",
      status: :enqueued,
      venue: venue,
      credential: "main",
      venue_product_symbol: venue |> venue_product_symbol,
      product_symbol: venue |> product_symbol,
      product_type: venue |> product_type,
      side: :buy,
      type: :limit,
      price: venue |> price(),
      qty: venue |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp build_open_order(order, order_response) do
    struct(NewOrders.Order, %{
      client_id: order.client_id,
      status: :open,
      venue_order_id: order_response.id,
      venue: order.venue,
      credential: "main",
      venue_product_symbol: order.venue |> venue_product_symbol,
      product_symbol: order.venue |> product_symbol,
      product_type: order.venue |> product_type,
      side: :buy,
      type: :limit,
      price: order.venue |> price(),
      qty: order.venue |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp venue_product_symbol("bitmex"), do: "XBTH19"
  defp venue_product_symbol("okex_swap"), do: "ETH-USD-SWAP"
  defp venue_product_symbol("okex_futures"), do: "ETH-USD-190426"
  defp venue_product_symbol("okex_spot"), do: "BTC-USDT"
  defp venue_product_symbol("ftx"), do: "BTC/USD"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol("bitmex"), do: "xbth19"
  defp product_symbol("okex_swap"), do: "eth_usd_swap"
  defp product_symbol("okex_futures"), do: "eth_usd_190426"
  defp product_symbol("okex_spot"), do: "btc_usdt"
  defp product_symbol("ftx"), do: "btc_usd"
  defp product_symbol(_), do: "ltc_btc"

  defp product_type("bitmex"), do: :future
  defp product_type("okex_swap"), do: :swap
  defp product_type("okex_futures"), do: :future
  defp product_type("okex_spot"), do: :spot
  defp product_type(_), do: :spot

  defp price("bitmex"), do: Decimal.new("100.5")
  defp price("okex_swap"), do: Decimal.new("100.5")
  defp price("okex_futures"), do: Decimal.new("100.5")
  defp price("okex_spot"), do: Decimal.new("61000.0")
  defp price("ftx"), do: Decimal.new("25000.5")
  defp price(_), do: Decimal.new("0.007")

  defp qty("bitmex"), do: Decimal.new(1)
  defp qty("okex_swap"), do: Decimal.new(5)
  defp qty("okex_futures"), do: Decimal.new(5)
  defp qty("okex_spot"), do: Decimal.new("0.0001")
  defp qty("ftx"), do: Decimal.new("0.0001")
  defp qty(_), do: Decimal.new("0.5")
end
