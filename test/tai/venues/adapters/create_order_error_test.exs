defmodule Tai.Venues.Adapters.CreateOrderErrorTest do
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

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_create_order_error()

  @test_adapters
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    [:timeout, :connect_timeout]
    |> Enum.map(fn error_reason ->
      @error_reason error_reason

      test "#{adapter.id} #{error_reason} error" do
        order = build_order(@adapter.id, :buy, :gtc, action: :unfilled)
        error = {:error, %HTTPoison.Error{reason: @error_reason}}

        with_mock HTTPoison,
          request: fn _url -> error end,
          post: fn _url, _body, _headers -> error end do
          assert {:error, reason} = Tai.Venue.create_order(order, @test_adapters)
          assert reason == @error_reason
        end
      end
    end)

    test "#{adapter.id} insufficient balance error" do
      order = build_order(@adapter.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_insufficient_balance" do
        assert Tai.Venue.create_order(order, @test_adapters) == {:error, :insufficient_balance}
      end
    end

    test "#{adapter.id} rate limited error" do
      order = build_order(@adapter.id, :buy, :gtc, action: :unfilled)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_rate_limited" do
        assert Tai.Venue.create_order(order, @test_adapters) == {:error, :rate_limited}
      end
    end

    test "#{adapter.id} unhandled error" do
      order = build_order(@adapter.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_unhandled_error" do
        assert {:error, {:unhandled, reason}} = Tai.Venue.create_order(order, @test_adapters)
        assert reason != nil
      end
    end

    test "#{adapter.id} nonce not increasing error" do
      order = build_order(@adapter.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_nonce_not_increasing" do
        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venue.create_order(order, @test_adapters)

        assert msg != nil
      end
    end

    test "#{adapter.id} overloaded error" do
      order = build_order(@adapter.id, :buy, :gtc, action: :unfilled)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_overloaded" do
        assert Tai.Venue.create_order(order, @test_adapters) == {:error, :overloaded}
      end
    end
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    action = Keyword.fetch!(opts, :action)
    post_only = Keyword.get(opts, :post_only, false)

    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      exchange_id: venue_id,
      account_id: :main,
      symbol: venue_id |> product_symbol,
      side: side,
      price: venue_id |> price(side, time_in_force, action),
      qty: venue_id |> qty(side, time_in_force, action),
      type: :limit,
      time_in_force: time_in_force,
      post_only: post_only
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(_), do: :ltc_btc

  defp price(:bitmex, :buy, :gtc, :filled), do: Decimal.new("4455")
  defp price(:bitmex, :sell, :gtc, :filled), do: Decimal.new("3767")
  defp price(:bitmex, :buy, :gtc, :unfilled), do: Decimal.new("100.5")
  defp price(:bitmex, :sell, :gtc, :unfilled), do: Decimal.new("50000.5")
  defp price(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new("4130")
  defp price(:bitmex, :sell, :gtc, :partially_filled), do: Decimal.new("3795.5")
  defp price(:bitmex, :buy, _, _), do: Decimal.new("10000.5")
  defp price(:bitmex, :sell, _, _), do: Decimal.new("1000.5")
  defp price(_, :buy, _, _), do: Decimal.new("0.007")
  defp price(_, :sell, _, _), do: Decimal.new("0.1")

  defp qty(:bitmex, :buy, :gtc, :filled), do: Decimal.new(150)
  defp qty(:bitmex, :sell, :gtc, :filled), do: Decimal.new(10)
  defp qty(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new(100)
  defp qty(:bitmex, :sell, :gtc, :partially_filled), do: Decimal.new(100)
  defp qty(:bitmex, _, :gtc, :insufficient_balance), do: Decimal.new(1_000_000)
  defp qty(:bitmex, :buy, _, _), do: Decimal.new(1)
  defp qty(:bitmex, :sell, _, _), do: Decimal.new(1)
  defp qty(_, _, :gtc, :insufficient_balance), do: Decimal.new(1_000)
  defp qty(_, :buy, _, _), do: Decimal.new("0.2")
  defp qty(_, :sell, _, _), do: Decimal.new("0.1")
end
