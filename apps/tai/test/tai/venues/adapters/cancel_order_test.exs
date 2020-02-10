defmodule Tai.Venues.Adapters.CancelOrderTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.Trading.OrderResponses

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
        assert %OrderResponses.CancelAccepted{} = order_response
        assert order_response.id != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id) do
    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      credential_id: :main,
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
    struct(Tai.Trading.Order, %{
      venue_order_id: order_response.id,
      venue_id: order.venue_id,
      credential_id: :main,
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

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(:okex_swap), do: :eth_usd_swap
  defp product_symbol(:okex_futures), do: :eth_usd_190426
  defp product_symbol(_), do: :ltc_btc

  defp product_type(:bitmex), do: :future
  defp product_type(:okex_swap), do: :swap
  defp product_type(:okex_futures), do: :future
  defp product_type(_), do: :spot

  defp price(:bitmex), do: Decimal.new("100.5")
  defp price(:okex_swap), do: Decimal.new("100.5")
  defp price(:okex_futures), do: Decimal.new("100.5")
  defp price(_), do: Decimal.new("0.007")

  defp qty(:bitmex), do: Decimal.new(1)
  defp qty(:okex_swap), do: Decimal.new(5)
  defp qty(:okex_futures), do: Decimal.new(5)
  defp qty(_), do: Decimal.new("0.5")
end
