defmodule Tai.Venues.Adapters.CancelOrderTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters()

  @test_adapters
  |> Enum.filter(fn {adapter_id, _} -> adapter_id == :bitmex end)
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    describe "#{adapter.id} cancel" do
      test "returns an order response with a canceled status & final quantities" do
        enqueued_order = build_enqueued_order(@adapter.id)

        use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_ok" do
          assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

          open_order = build_open_order(enqueued_order, order_response)

          assert {:ok, order_response} = Tai.Venue.cancel_order(open_order, @test_adapters)
          assert order_response.id != nil
          assert order_response.status == :canceled
          assert order_response.leaves_qty == Decimal.new(0)
          assert %DateTime{} = order_response.venue_updated_at
        end
      end

      test "timeout returns an error tuple" do
        enqueued_order = build_enqueued_order(@adapter.id)

        use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_timeout" do
          assert {:ok, order_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

          open_order = build_open_order(enqueued_order, order_response)

          assert Tai.Venue.cancel_order(open_order, @test_adapters) == {:error, :timeout}
        end
      end
    end
  end)

  defp build_enqueued_order(venue_id) do
    struct(Tai.Trading.Order, %{
      exchange_id: venue_id,
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
      exchange_id: order.exchange_id,
      account_id: :main,
      symbol: order.exchange_id |> product_symbol,
      side: :buy,
      price: order.exchange_id |> price(),
      qty: order.exchange_id |> qty(),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(_), do: :btc_usd

  defp price(:bitmex), do: Decimal.new("100.5")

  defp qty(:bitmex), do: Decimal.new(1)
end
