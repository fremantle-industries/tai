defmodule Tai.Venues.Adapters.CancelOrderTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.Orders

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order()
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
        assert order_response.id != nil
        assert order_response.status == :canceled
        assert order_response.leaves_qty == Decimal.new(0)
      end
    end
  end)

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
        assert %Orders.Responses.CancelAccepted{} = order_response
        assert order_response.id != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id) do
    struct(Tai.Orders.Order, %{
      client_id: "f5559e85-7a3c-4c07-94d8-5e7a74079733",
      venue_id: venue_id,
      credential_id: :main,
      venue_product_symbol: venue_id |> venue_product_symbol,
      product_symbol: venue_id |> product_symbol,
      product_type: venue_id |> product_type,
      side: :buy,
      type: :limit,
      price: venue_id |> price(),
      qty: venue_id |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp build_open_order(order, order_response) do
    struct(Tai.Orders.Order, %{
      client_id: order.client_id,
      venue_order_id: order_response.id,
      venue_id: order.venue_id,
      credential_id: :main,
      venue_product_symbol: order.venue_id |> venue_product_symbol,
      product_symbol: order.venue_id |> product_symbol,
      product_type: order.venue_id |> product_type,
      side: :buy,
      type: :limit,
      price: order.venue_id |> price(),
      qty: order.venue_id |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp venue_product_symbol(:bitmex), do: "XBTH19"
  defp venue_product_symbol(:okex_swap), do: "ETH-USD-SWAP"
  defp venue_product_symbol(:okex_futures), do: "ETH-USD-190426"
  defp venue_product_symbol(:ftx), do: "BTC/USD"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(:okex_swap), do: :eth_usd_swap
  defp product_symbol(:okex_futures), do: :eth_usd_190426
  defp product_symbol(:ftx), do: :btc_usd
  defp product_symbol(_), do: :ltc_btc

  defp product_type(:bitmex), do: :future
  defp product_type(:okex_swap), do: :swap
  defp product_type(:okex_futures), do: :future
  defp product_type(_), do: :spot

  defp price(:bitmex), do: Decimal.new("100.5")
  defp price(:okex_swap), do: Decimal.new("100.5")
  defp price(:okex_futures), do: Decimal.new("100.5")
  defp price(:ftx), do: Decimal.new("25000.5")
  defp price(_), do: Decimal.new("0.007")

  defp qty(:bitmex), do: Decimal.new(1)
  defp qty(:okex_swap), do: Decimal.new(5)
  defp qty(:okex_futures), do: Decimal.new(5)
  defp qty(:ftx), do: Decimal.new("0.0001")
  defp qty(_), do: Decimal.new("0.5")
end
