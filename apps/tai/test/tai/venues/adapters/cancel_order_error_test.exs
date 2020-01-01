defmodule Tai.Venues.Adapters.CancelOrderErrorTest do
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

  @not_found_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_not_found()
  @timeout_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_timeout()
  @overloaded_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_overloaded()
  @nonce_not_increasing_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_nonce_not_increasing()
  @rate_limited_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_rate_limited()
  @unhandled_test_adapters Tai.TestSupport.Helpers.test_venue_adapters_cancel_order_error_unhandled()

  @not_found_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} not found error" do
      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_error_not_found" do
        order = build_not_found_order(@adapter.id)

        assert Tai.Venues.Client.cancel_order(order, @not_found_test_adapters) ==
                 {:error, :not_found}
      end
    end
  end)

  @timeout_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{adapter.id} #{error_reason} error" do
        enqueued_order = build_enqueued_order(@adapter.id)

        use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_#{@error_reason}" do
          assert {:ok, order_response} =
                   Tai.Venues.Client.create_order(enqueued_order, @timeout_test_adapters)

          open_order = build_open_order(enqueued_order, order_response)

          with_mock HTTPoison,
            request: fn _url -> {:error, %HTTPoison.Error{reason: @error_reason}} end,
            post: fn _url, _body, _headers ->
              {:error, %HTTPoison.Error{reason: @error_reason}}
            end do
            assert {:error, reason} =
                     Tai.Venues.Client.cancel_order(open_order, @timeout_test_adapters)

            assert reason == @error_reason
          end
        end
      end
    end)
  end)

  @overloaded_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} overloaded error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_overloaded_error" do
        assert {:ok, order_response} =
                 Tai.Venues.Client.create_order(enqueued_order, @overloaded_test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert Tai.Venues.Client.cancel_order(open_order, @overloaded_test_adapters) ==
                 {:error, :overloaded}
      end
    end
  end)

  @nonce_not_increasing_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} nonce not increasing error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_nonce_not_increasing_error" do
        assert {:ok, order_response} =
                 Tai.Venues.Client.create_order(
                   enqueued_order,
                   @nonce_not_increasing_test_adapters
                 )

        open_order = build_open_order(enqueued_order, order_response)

        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venues.Client.cancel_order(open_order, @nonce_not_increasing_test_adapters)

        assert msg != nil
      end
    end
  end)

  @rate_limited_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} rate limited error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_rate_limited_error" do
        assert {:ok, order_response} =
                 Tai.Venues.Client.create_order(enqueued_order, @rate_limited_test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert Tai.Venues.Client.cancel_order(open_order, @rate_limited_test_adapters) ==
                 {:error, :rate_limited}
      end
    end
  end)

  @unhandled_test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    test "#{adapter.id} unhandled error" do
      enqueued_order = build_enqueued_order(@adapter.id)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/cancel_unhandled_error" do
        assert {:ok, order_response} =
                 Tai.Venues.Client.create_order(enqueued_order, @unhandled_test_adapters)

        open_order = build_open_order(enqueued_order, order_response)

        assert {:error, {:unhandled, error}} =
                 Tai.Venues.Client.cancel_order(open_order, @unhandled_test_adapters)

        assert error != nil
      end
    end
  end)

  defp build_not_found_order(venue_id) do
    struct(
      Tai.Trading.Order,
      venue_id: venue_id,
      account_id: :main,
      product_symbol: venue_id |> product_symbol,
      product_type: venue_id |> product_type,
      venue_order_id: "1"
    )
  end

  defp build_enqueued_order(venue_id) do
    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      account_id: :main,
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
      account_id: :main,
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
  defp product_symbol(:okex_futures), do: :eth_usd_190628
  defp product_symbol(:okex_swap), do: :eth_usd_swap
  defp product_symbol(_), do: :ltc_btc

  defp product_type(:okex_swap), do: :swap
  defp product_type(:binance), do: :spot
  defp product_type(_), do: :future

  defp price(:bitmex), do: Decimal.new("100.5")
  defp price(:okex_futures), do: Decimal.new("100.5")
  defp price(:okex_swap), do: Decimal.new("100.5")
  defp price(:binance), do: Decimal.new("0.007")

  defp qty(:bitmex), do: Decimal.new(1)
  defp qty(:okex_futures), do: Decimal.new(1)
  defp qty(:okex_swap), do: Decimal.new(1)
  defp qty(:binance), do: Decimal.new(1)
end
