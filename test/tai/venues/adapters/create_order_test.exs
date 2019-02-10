defmodule Tai.Venues.Adapters.CreateOrderTest do
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
  @sides [:buy, :sell]

  @test_adapters
  |> Enum.filter(fn {adapter_id, _} -> adapter_id == :bitmex end)
  |> Enum.map(fn {_, adapter} ->
    @adapter adapter

    @sides
    |> Enum.each(fn side ->
      @side side

      describe "#{adapter.id} #{side} limit fok" do
        test "filled" do
          order = build_order(@adapter.id, @side, :fok, action: :filled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_fok_filled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == order_response.original_size
            assert order_response.status == :filled
            assert order_response.avg_price != Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end

        test "expired" do
          order = build_order(@adapter.id, @side, :fok, action: :expired)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_fok_expired" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :expired
            assert order_response.avg_price == Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end
      end

      describe "#{adapter.id} #{side} limit ioc" do
        test "filled" do
          order = build_order(@adapter.id, @side, :ioc, action: :filled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_ioc_filled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == order_response.original_size
            assert order_response.status == :filled
            assert order_response.avg_price != Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end

        test "partially filled" do
          order = build_order(@adapter.id, @side, :ioc, action: :partially_filled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_ioc_partially_filled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty != Decimal.new(0)
            assert order_response.cumulative_qty != order_response.original_size
            assert order_response.status == :expired
            assert order_response.avg_price != Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end

        test "unfilled" do
          order = build_order(@adapter.id, @side, :ioc, action: :unfilled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_ioc_unfilled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :expired
            assert order_response.avg_price == Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end
      end

      describe "#{adapter.id} #{side} limit gtc" do
        test "filled" do
          order = build_order(@adapter.id, @side, :gtc, post_only: false, action: :filled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_gtc_filled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == order_response.original_size
            assert order_response.status == :filled
            assert order_response.avg_price != Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end

        test "partially filled" do
          order =
            build_order(@adapter.id, @side, :gtc, post_only: false, action: :partially_filled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_gtc_partially_filled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.leaves_qty
            assert order_response.cumulative_qty != order_response.original_size
            assert order_response.cumulative_qty != Decimal.new(0)
            assert order_response.leaves_qty != Decimal.new(0)
            assert order_response.leaves_qty != order_response.original_size
            assert order_response.status == :open
            assert order_response.avg_price != Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end

        test "unfilled" do
          order = build_order(@adapter.id, @side, :gtc, post_only: false, action: :unfilled)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_gtc_unfilled" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == order_response.original_size
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :open
            assert order_response.avg_price == Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end

        test "rejected" do
          order = build_order(@adapter.id, @side, :gtc, post_only: true, action: :rejected)

          use_cassette "venue_adapters/shared/orders/#{@adapter.id}/#{@side}_limit_gtc_rejected" do
            assert {:ok, order_response} = Tai.Venue.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :rejected
            assert order_response.avg_price == Decimal.new(0)
            assert %DateTime{} = order_response.venue_created_at
          end
        end
      end
    end)

    test "#{adapter.id} timeout" do
      order = build_order(@adapter.id, :buy, :gtc, action: :unfilled)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_timeout" do
        assert {:error, :timeout} = Tai.Venue.create_order(order, @test_adapters)
      end
    end

    test "#{adapter.id} insufficient balance" do
      order = build_order(@adapter.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_insufficient_balance" do
        assert {:error, :insufficient_balance} = Tai.Venue.create_order(order, @test_adapters)
      end
    end

    test "#{adapter.id} nonce not increasing" do
      order = build_order(@adapter.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_nonce_not_increasing" do
        assert {:error, {:nonce_not_increasing, msg}} =
                 Tai.Venue.create_order(order, @test_adapters)

        assert msg != nil
      end
    end

    test "#{adapter.id} unhandled" do
      order = build_order(@adapter.id, :buy, :gtc, action: :insufficient_balance)

      use_cassette "venue_adapters/shared/orders/#{@adapter.id}/create_order_unhandled" do
        assert {:error, {:unhandled, reason}} = Tai.Venue.create_order(order, @test_adapters)
        assert reason != nil
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
      size: venue_id |> size(side, time_in_force, action),
      time_in_force: time_in_force,
      post_only: post_only
    })
  end

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(_), do: :btc_usd

  defp price(:bitmex, :buy, :fok, :filled), do: Decimal.new("4455.5")
  defp price(:bitmex, :sell, :fok, :filled), do: Decimal.new("3788.5")
  defp price(:bitmex, :buy, :fok, :expired), do: Decimal.new("4450.5")
  defp price(:bitmex, :sell, :fok, :expired), do: Decimal.new("3790.5")
  defp price(:bitmex, :buy, :ioc, :filled), do: Decimal.new("4455.5")
  defp price(:bitmex, :sell, :ioc, :filled), do: Decimal.new("3785.5")
  defp price(:bitmex, :buy, :ioc, :partially_filled), do: Decimal.new("4458.5")
  defp price(:bitmex, :sell, :ioc, :partially_filled), do: Decimal.new("3749.5")
  defp price(:bitmex, :buy, :ioc, :unfilled), do: Decimal.new("4450.5")
  defp price(:bitmex, :sell, :ioc, :unfilled), do: Decimal.new("3755.5")
  defp price(:bitmex, :buy, :gtc, :filled), do: Decimal.new("4455")
  defp price(:bitmex, :sell, :gtc, :filled), do: Decimal.new("3767")
  defp price(:bitmex, :buy, :gtc, :unfilled), do: Decimal.new("100.5")
  defp price(:bitmex, :sell, :gtc, :unfilled), do: Decimal.new("50000.5")
  defp price(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new("4130")
  defp price(:bitmex, :sell, :gtc, :partially_filled), do: Decimal.new("3795.5")
  defp price(:bitmex, :buy, _, _), do: Decimal.new("10000.5")
  defp price(:bitmex, :sell, _, _), do: Decimal.new("1000.5")
  defp price(_, :buy, _, _), do: Decimal.new("100.1")
  defp price(_, :sell, _, _), do: Decimal.new("50000.5")

  defp size(:bitmex, _, :fok, _), do: Decimal.new(10)
  defp size(:bitmex, _, :ioc, :partially_filled), do: Decimal.new(150)
  defp size(:bitmex, _, :ioc, _), do: Decimal.new(10)
  defp size(:bitmex, :buy, :gtc, :filled), do: Decimal.new(150)
  defp size(:bitmex, :sell, :gtc, :filled), do: Decimal.new(10)
  defp size(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new(100)
  defp size(:bitmex, :sell, :gtc, :partially_filled), do: Decimal.new(100)
  defp size(:bitmex, _, :gtc, :insufficient_balance), do: Decimal.new(1_000_000)
  defp size(:bitmex, :buy, _, _), do: Decimal.new(1)
  defp size(:bitmex, :sell, _, _), do: Decimal.new(1)
  defp size(_, :buy, _, _), do: Decimal.new("1.1")
  defp size(_, :sell, _, _), do: Decimal.new("0.1")
end
