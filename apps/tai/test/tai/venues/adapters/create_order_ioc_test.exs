defmodule Tai.Venues.Adapters.CreateOrderIocTest do
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

  @test_adapters Tai.TestSupport.Helpers.test_venue_adapters_create_order_ioc()
  @sides [:buy, :sell]

  @test_adapters
  |> Enum.map(fn {_, venue} ->
    @venue venue

    @sides
    |> Enum.each(fn side ->
      @side side

      describe "#{venue.id} #{side} limit ioc" do
        test "filled" do
          order = build_order(@venue.id, @side, :ioc, action: :filled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_filled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == order_response.original_size
            assert order_response.status == :filled
            assert %DateTime{} = order_response.venue_timestamp
          end
        end

        test "partially filled" do
          order = build_order(@venue.id, @side, :ioc, action: :partially_filled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_partially_filled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty != Decimal.new(0)
            assert order_response.cumulative_qty != order_response.original_size
            assert order_response.status == :expired
            assert %DateTime{} = order_response.venue_timestamp
          end
        end

        test "unfilled" do
          order = build_order(@venue.id, @side, :ioc, action: :unfilled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_unfilled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order, @test_adapters)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :expired
            assert %DateTime{} = order_response.venue_timestamp
          end
        end
      end
    end)
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    action = Keyword.fetch!(opts, :action)
    post_only = Keyword.get(opts, :post_only, false)

    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      account_id: :main,
      product_symbol: venue_id |> product_symbol,
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

  defp price(:bitmex, :buy, :ioc, :filled), do: Decimal.new("4455.5")
  defp price(:bitmex, :sell, :ioc, :filled), do: Decimal.new("3785.5")
  defp price(:bitmex, :buy, :ioc, :partially_filled), do: Decimal.new("4458.5")
  defp price(:bitmex, :sell, :ioc, :partially_filled), do: Decimal.new("3749.5")
  defp price(:bitmex, :buy, :ioc, :unfilled), do: Decimal.new("4450.5")
  defp price(:bitmex, :sell, :ioc, :unfilled), do: Decimal.new("3755.5")
  defp price(:bitmex, :buy, _, _), do: Decimal.new("10000.5")
  defp price(:bitmex, :sell, _, _), do: Decimal.new("1000.5")
  defp price(_, :buy, _, _), do: Decimal.new("0.007")
  defp price(_, :sell, _, _), do: Decimal.new("0.1")

  defp qty(:bitmex, _, :ioc, :partially_filled), do: Decimal.new(150)
  defp qty(:bitmex, _, :ioc, _), do: Decimal.new(10)
  defp qty(:bitmex, :buy, _, _), do: Decimal.new(1)
  defp qty(:bitmex, :sell, _, _), do: Decimal.new(1)
  defp qty(_, :buy, _, _), do: Decimal.new("0.2")
  defp qty(_, :sell, _, _), do: Decimal.new("0.1")
end
