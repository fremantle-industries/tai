defmodule Tai.Venues.Adapters.AmendOrderTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock
  alias Tai.NewOrders

  setup_all do
    HTTPoison.start()
  end

  Tai.TestSupport.Helpers.test_venue_adapters_amend_order_accepted()
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

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_price_and_qty_ok" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:ok, amend_response} = Tai.Venues.Client.amend_order(open_order, attrs)
        assert %NewOrders.Responses.AmendAccepted{} = amend_response
        assert amend_response.id == open_order.venue_order_id
        assert amend_response.received_at != nil
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end

    test "#{venue.id} can change price" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_price = amend_price(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, price: amend_price)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_price_ok" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:ok, amend_response} = Tai.Venues.Client.amend_order(open_order, attrs)
        assert %NewOrders.Responses.AmendAccepted{} = amend_response
        assert amend_response.id == open_order.venue_order_id
        assert amend_response.received_at != nil
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end

    test "#{venue.id} can change qty" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_qty = amend_qty(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_qty_ok" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:ok, amend_response} = Tai.Venues.Client.amend_order(open_order, attrs)
        assert %NewOrders.Responses.AmendAccepted{} = amend_response
        assert amend_response.id == open_order.venue_order_id
        assert amend_response.received_at != nil
        assert %DateTime{} = amend_response.venue_timestamp
      end
    end

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{venue.id} #{error_reason} error" do
        enqueued_order = build_enqueued_order(@venue.id, :buy)
        amend_qty = amend_qty(@venue.id, enqueued_order.side)
        attrs = amend_attrs(@venue.id, qty: amend_qty)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_#{@error_reason}" do
          assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

          open_order = build_open_order(enqueued_order, amend_response)

          with_mock HTTPoison,
            request: fn _url -> {:error, %HTTPoison.Error{reason: @error_reason}} end do
            assert {:error, reason} = Tai.Venues.Client.amend_order(open_order, attrs)

            assert reason == @error_reason
          end
        end
      end
    end)

    test "#{venue.id} nonce not increasing error" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_qty = amend_qty(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_nonce_not_increasing" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venues.Client.amend_order(open_order, attrs)

        assert msg =~ ~r/Nonce is not increasing/
      end
    end

    test "#{venue.id} overloaded error" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_qty = amend_qty(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_overloaded_error" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert Tai.Venues.Client.amend_order(open_order, attrs) ==
                 {:error, :overloaded}
      end
    end

    test "#{venue.id} rate limited error" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_qty = amend_qty(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_rate_limited_error" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert Tai.Venues.Client.amend_order(open_order, attrs) ==
                 {:error, :rate_limited}
      end
    end

    test "#{venue.id} unhandled error" do
      enqueued_order = build_enqueued_order(@venue.id, :buy)
      amend_qty = amend_qty(@venue.id, enqueued_order.side)
      attrs = amend_attrs(@venue.id, qty: amend_qty)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/amend_unhandled_error" do
        assert {:ok, amend_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, amend_response)

        assert {:error, {:unhandled, error}} = Tai.Venues.Client.amend_order(open_order, attrs)

        assert error != nil
      end
    end
  end)

  defp build_enqueued_order(venue_id, side) do
    venue = venue_id |> Atom.to_string()

    struct(NewOrders.Order, %{
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
    struct(NewOrders.Order, %{
      venue_order_id: amend_response.id,
      venue: order.venue,
      credential: order.credential,
      product_symbol: order.venue |> product_symbol,
      side: order.side,
      price: order.venue |> price(order.side),
      qty: order.venue |> qty(order.side),
      cumulative_qty: Decimal.new(0),
      time_in_force: :gtc,
      post_only: true
    })
  end

  defp product_symbol("bitmex"), do: "xbth19"
  defp product_symbol(_), do: "btc_usd"

  defp price("bitmex", :buy), do: Decimal.new("2001.5")

  defp qty("bitmex", _), do: Decimal.new(2)

  defp amend_price(:bitmex, :buy), do: Decimal.new("2300.5")

  defp amend_qty(:bitmex, :buy), do: Decimal.new(10)

  defp amend_attrs(:bitmex, price: price, qty: qty), do: %{price: price, qty: qty}
  defp amend_attrs(:bitmex, price: price), do: %{price: price}
  defp amend_attrs(:bitmex, qty: qty), do: %{qty: qty}
end
