defmodule Tai.Venues.Adapters.CancelOrderErrorTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock
  alias Tai.NewOrders

  setup_all do
    HTTPoison.start()
  end

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_not_found()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} not found error" do
      use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_error_not_found" do
        order = build_not_found_order(@venue.id)

        assert Tai.Venues.Client.cancel_order(order) == {:error, :not_found}
      end
    end
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_timeout()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{venue.id} #{error_reason} error" do
        enqueued_order = build_enqueued_order(@venue.id)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_#{@error_reason}" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(enqueued_order)

          open_order = build_open_order(enqueued_order, order_response)

          with_mock HTTPoison,
            request: fn _url -> {:error, %HTTPoison.Error{reason: @error_reason}} end,
            post: fn _url, _body, _headers ->
              {:error, %HTTPoison.Error{reason: @error_reason}}
            end do
            assert {:error, reason} = Tai.Venues.Client.cancel_order(open_order)
            assert reason == @error_reason
          end
        end
      end
    end)
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_overloaded()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} overloaded error" do
      enqueued_order = build_enqueued_order(@venue.id)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_overloaded_error" do
        assert {:ok, order_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, order_response)

        assert Tai.Venues.Client.cancel_order(open_order) == {:error, :overloaded}
      end
    end
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_nonce_not_increasing()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} nonce not increasing error" do
      enqueued_order = build_enqueued_order(@venue.id)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_nonce_not_increasing_error" do
        assert {:ok, order_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:error, {:nonce_not_increasing, msg}} = Tai.Venues.Client.cancel_order(open_order)
        assert msg != nil
      end
    end
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_rate_limited()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} rate limited error" do
      enqueued_order = build_enqueued_order(@venue.id)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_rate_limited_error" do
        assert {:ok, order_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, order_response)

        assert Tai.Venues.Client.cancel_order(open_order) == {:error, :rate_limited}
      end
    end
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_unhandled()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    test "#{venue.id} unhandled error" do
      enqueued_order = build_enqueued_order(@venue.id)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/cancel_unhandled_error" do
        assert {:ok, order_response} = Tai.Venues.Client.create_order(enqueued_order)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:error, {:unhandled, error}} = Tai.Venues.Client.cancel_order(open_order)
        assert error != nil
      end
    end
  end)

  defp build_not_found_order(venue_id) do
    venue = venue_id |> Atom.to_string()

    struct(
      NewOrders.Order,
      client_id: "6b677ec7-4b92-41e9-9a02-171fe99a2192",
      venue: venue,
      credential: "main",
      venue_product_symbol: venue |> venue_product_symbol,
      product_symbol: venue |> product_symbol,
      product_type: venue |> product_type,
      venue_order_id: "1"
    )
  end

  defp build_enqueued_order(venue_id) do
    venue = venue_id |> Atom.to_string()

    struct(NewOrders.Order, %{
      client_id: Ecto.UUID.generate(),
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
  defp venue_product_symbol("okex_futures"), do: "ETH-USD-190628"
  defp venue_product_symbol("okex_swap"), do: "ETH-USD-SWAP"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol("bitmex"), do: "xbth19"
  defp product_symbol("okex_futures"), do: "eth_usd_190628"
  defp product_symbol("okex_swap"), do: "eth_usd_swap"
  defp product_symbol(_), do: "ltc_btc"

  defp product_type("okex_swap"), do: :swap
  defp product_type("binance"), do: :spot
  defp product_type(_), do: :future

  defp price("bitmex"), do: Decimal.new("100.5")
  defp price("okex_futures"), do: Decimal.new("100.5")
  defp price("okex_swap"), do: Decimal.new("100.5")
  defp price("binance"), do: Decimal.new("0.007")

  defp qty("bitmex"), do: Decimal.new(1)
  defp qty("okex_futures"), do: Decimal.new(1)
  defp qty("okex_swap"), do: Decimal.new(1)
  defp qty("binance"), do: Decimal.new(1)
end
