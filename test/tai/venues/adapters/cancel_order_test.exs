defmodule Tai.Venues.Adapters.CancelOrderTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.Trading.OrderResponses

  setup_all do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order()
  @accepted_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_accepted()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} returns an order response with a canceled status & final quantities" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_ok" do
        assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:ok, order_response} = Tai.Venue.cancel_order(open_order, @test_adapters)
        assert order_response.id != nil
        assert order_response.status == :canceled
        assert order_response.leaves_qty == Decimal.new(0)
        assert %DateTime{} = order_response.venue_timestamp
      end
    end
  end)

  @accepted_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} returns an order response with a canceled status & final quantities" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_ok" do
        assert {:ok, order_response} =
                 Tai.Venue.create_order(enqueued_order, @accepted_test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:ok, order_response} = Tai.Venue.cancel_order(open_order, @accepted_test_adapters)
        assert %OrderResponses.CancelAccepted{} = order_response
        assert order_response.id != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id) do
    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      account_id: :main,
      symbol: venue_id |> product_symbol,
      side: :buy,
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
      account_id: :main,
      symbol: order.venue_id |> product_symbol,
      side: :buy,
      price: order.venue_id |> price(),
      qty: order.venue_id |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(:okex), do: :eth_usd_190426
  defp product_symbol(_), do: :btc_usd

  defp price(:bitmex), do: Decimal.new("100.5")
  defp price(:okex), do: Decimal.new("100.5")

  defp qty(:bitmex), do: Decimal.new(1)
  defp qty(:okex), do: Decimal.new(1)
end
