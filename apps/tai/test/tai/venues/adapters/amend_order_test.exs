defmodule Tai.Venues.Adapters.AmendOrderTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock

  setup_all do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!(Tai.TestSupport.Mocks.Server)
    HTTPoison.start()
  end

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_amend_order()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} can change price and qty" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_price = amend_price(@adapter.id, enqueued_order.side)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, price: amend_price, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_price_and_qty_ok" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:ok, amend_response} = Tai.Venue.amend_order(open_order, attrs, @test_adapters)

        assert amend_response.id == open_order.venue_order_id
        assert amend_response.status == :open
        assert amend_response.price == amend_price
        assert amend_response.leaves_qty == amend_qty
        assert amend_response.cumulative_qty == enqueued_order.cumulative_qty
        assert %DateTime{} = amend_response.received_at
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end

    test "#{adapter.id} can change price" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_price = amend_price(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, price: amend_price)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_price_ok" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:ok, amend_response} = Tai.Venue.amend_order(open_order, attrs, @test_adapters)

        assert amend_response.id == open_order.venue_order_id
        assert amend_response.status == :open
        assert amend_response.price == amend_price
        assert amend_response.leaves_qty == enqueued_order.qty
        assert amend_response.cumulative_qty == enqueued_order.cumulative_qty
        assert %DateTime{} = amend_response.received_at
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end

    test "#{adapter.id} can change qty" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_qty_ok" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:ok, amend_response} = Tai.Venue.amend_order(open_order, attrs, @test_adapters)

        assert amend_response.id == open_order.venue_order_id
        assert amend_response.status == :open
        assert amend_response.leaves_qty == amend_qty
        assert amend_response.price == enqueued_order.price
        assert amend_response.cumulative_qty == enqueued_order.cumulative_qty
        assert %DateTime{} = amend_response.received_at
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{adapter.id} #{error_reason} error" do
        enqueued_order = build_enqueued_order(@adapter.id, :buy)
        amend_qty = amend_qty(@adapter.id, enqueued_order.side)
        attrs = amend_attrs(@adapter.id, qty: amend_qty)

        use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_#{@error_reason}" do
          assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

          open_order = build_open_order(enqueued_order, amend_response)

          with_mock HTTPoison,
            request: fn _url -> {:error, %HTTPoison.Error{reason: @error_reason}} end do
            assert {:error, reason} = Tai.Venue.amend_order(open_order, attrs, @test_adapters)
            assert reason == @error_reason
          end
        end
      end
    end)

    test "#{adapter.id} nonce not increasing error" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_nonce_not_increasing" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venue.amend_order(open_order, attrs, @test_adapters)

        assert msg =~ ~r/Nonce is not increasing/
      end
    end

    test "#{adapter.id} overloaded error" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_overloaded_error" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert Tai.Venue.amend_order(open_order, attrs, @test_adapters) == {:error, :overloaded}
      end
    end

    test "#{adapter.id} rate limited error" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_rate_limited_error" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert Tai.Venue.amend_order(open_order, attrs, @test_adapters) == {:error, :rate_limited}
      end
    end

    test "#{adapter.id} unhandled error" do
      enqueued_order = build_enqueued_order(@adapter.id, :buy)
      amend_qty = amend_qty(@adapter.id, enqueued_order.side)
      attrs = amend_attrs(@adapter.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/amend_unhandled_error" do
        assert {:ok, amend_response} = Tai.Venue.create_order(enqueued_order, @test_adapters)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:error, {:unhandled, error}} =
                 Tai.Venue.amend_order(open_order, attrs, @test_adapters)

        assert error != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id, side) do
    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      account_id: :main,
      product_symbol: venue_id |> product_symbol,
      side: side,
      price: venue_id |> price(side),
      qty: venue_id |> qty(side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp build_open_order(order, amend_response) do
    struct(Tai.Trading.Order, %{
      venue_order_id: amend_response.id,
      venue_id: order.venue_id,
      account_id: :main,
      product_symbol: order.venue_id |> product_symbol,
      side: order.side,
      price: order.venue_id |> price(order.side),
      qty: order.venue_id |> qty(order.side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(_), do: :btc_usd

  defp price(:bitmex, :buy), do: Decimal.new("2001.5")

  defp amend_price(:bitmex, :buy), do: Decimal.new("2300.5")

  defp qty(:bitmex, _), do: Decimal.new(2)

  defp amend_qty(:bitmex, :buy), do: Decimal.new(10)

  defp amend_attrs(:bitmex, price: price, qty: qty), do: %{price: price, qty: qty}
  defp amend_attrs(:bitmex, price: price), do: %{price: price}
  defp amend_attrs(:bitmex, qty: qty), do: %{qty: qty}
end
