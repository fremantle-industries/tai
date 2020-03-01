defmodule Tai.Venues.Adapters.CreateOrderErrorTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Mock

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    HTTPoison.start()
  end

  @insufficient_balance_venues Tai.TestSupport.Helpers.test_venue_adapters_create_order_error_insufficient_balance()
  @insufficient_balance_venues
  |> Enum.map(fn {_, venue} ->
    @venue venue

    test "#{venue.id} insufficient balance" do
      order = build_order(@venue.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/create_order_insufficient_balance" do
        assert {:error, reason} =
                 Tai.Venues.Client.create_order(order, @insufficient_balance_venues)

        assert reason == :insufficient_balance
      end
    end
  end)

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_create_order_error()
  @test_adapters
  |> Enum.map(fn {_, venue} ->
    @venue venue

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{venue.id} #{error_reason}" do
        order = build_order(@venue.id, :buy, :gtc, action: :unfilled)
        error = {:error, %HTTPoison.Error{reason: @error_reason}}

        with_mock HTTPoison,
          request: fn _url -> error end,
          post: fn _url, _body, _headers -> error end do
          assert {:error, reason} = Tai.Venues.Client.create_order(order, @test_adapters)
          assert reason == @error_reason
        end
      end
    end)

    test "#{venue.id} rejected" do
      order = build_order(@venue.id, :buy, :gtc, post_only: true, action: :rejected)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/rejected" do
        assert {:ok, order_response} = Tai.Venues.Client.create_order(order, @test_adapters)

        assert order_response.id != nil
        assert %Decimal{} = order_response.original_size
        assert order_response.leaves_qty == Decimal.new(0)
        assert order_response.cumulative_qty == Decimal.new(0)
        assert order_response.status == :rejected
        assert %DateTime{} = order_response.venue_timestamp
      end
    end

    test "#{venue.id} rate limited" do
      order = build_order(@venue.id, :buy, :gtc, action: :unfilled)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/create_order_rate_limited" do
        assert Tai.Venues.Client.create_order(order, @test_adapters) == {:error, :rate_limited}
      end
    end

    test "#{venue.id} unhandled" do
      order = build_order(@venue.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/create_order_unhandled_error" do
        assert {:error, {:unhandled, reason}} =
                 Tai.Venues.Client.create_order(order, @test_adapters)

        assert reason != nil
      end
    end

    test "#{venue.id} nonce not increasing" do
      order = build_order(@venue.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/create_order_nonce_not_increasing" do
        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venues.Client.create_order(order, @test_adapters)

        assert msg != nil
      end
    end

    test "#{venue.id} overloaded" do
      order = build_order(@venue.id, :buy, :gtc, action: :unfilled)

      use_cassette "venue_adapters/shared/orders/#{@venue.id}/create_order_overloaded" do
        assert Tai.Venues.Client.create_order(order, @test_adapters) == {:error, :overloaded}
      end
    end
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    action = Keyword.fetch!(opts, :action)
    post_only = Keyword.get(opts, :post_only, false)

    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      credential_id: :main,
      product_symbol: venue_id |> product_symbol,
      product_type: venue_id |> product_type,
      side: side,
      price: venue_id |> price(side, time_in_force, action),
      qty: venue_id |> qty(side, time_in_force, action),
      type: :limit,
      time_in_force: time_in_force,
      post_only: post_only
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(:okex_futures), do: :eth_usd_190510
  defp product_symbol(:okex_swap), do: :eth_usd_swap
  defp product_symbol(_), do: :ltc_btc

  defp product_type(:okex_swap), do: :swap
  defp product_type(_), do: :future

  defp price(:bitmex, :buy, :gtc, :filled), do: Decimal.new("4455")
  defp price(:bitmex, :buy, :gtc, :unfilled), do: Decimal.new("100.5")
  defp price(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new("4130")
  defp price(:bitmex, :buy, _, _), do: Decimal.new("10000.5")
  defp price(:okex_futures, :buy, :gtc, :insufficient_balance), do: Decimal.new("140.5")
  defp price(:okex_swap, :buy, :gtc, :insufficient_balance), do: Decimal.new("140.5")
  defp price(_, :buy, _, _), do: Decimal.new("0.007")

  defp qty(:bitmex, :buy, :gtc, :filled), do: Decimal.new(150)
  defp qty(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new(100)
  defp qty(:bitmex, :buy, :gtc, :insufficient_balance), do: Decimal.new(1_000_000)
  defp qty(:bitmex, :buy, _, _), do: Decimal.new(1)
  defp qty(:okex_futures, :buy, _, _), do: Decimal.new(5)
  defp qty(:okex_swap, :buy, _, _), do: Decimal.new(5)
  defp qty(_, :buy, :gtc, :insufficient_balance), do: Decimal.new(1_000)
  defp qty(_, :buy, _, _), do: Decimal.new("0.2")
end
