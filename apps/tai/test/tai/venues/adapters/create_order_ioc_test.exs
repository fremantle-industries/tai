defmodule Tai.Venues.Adapters.CreateOrderIocTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.NewOrders

  setup_all do
    HTTPoison.start()
  end

  @sides [:buy, :sell]

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_ioc()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      describe "#{venue.id} #{side} limit ioc" do
        test "filled" do
          order = build_order(@venue.id, @side, :ioc, action: :filled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_filled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == order_response.original_size
            assert order_response.status == :filled
            assert %DateTime{} = order_response.venue_timestamp
            assert order_response.received_at != nil
          end
        end

        test "partially filled" do
          order = build_order(@venue.id, @side, :ioc, action: :partially_filled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_partially_filled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty != Decimal.new(0)
            assert order_response.cumulative_qty != order_response.original_size
            assert order_response.status == :expired
            assert %DateTime{} = order_response.venue_timestamp
            assert order_response.received_at != nil
          end
        end

        test "unfilled" do
          order = build_order(@venue.id, @side, :ioc, action: :unfilled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_unfilled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :expired
            assert %DateTime{} = order_response.venue_timestamp
            assert order_response.received_at != nil
          end
        end
      end
    end)
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_ioc_accepted()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      test "#{venue.id} #{side} limit ioc unfilled accepted" do
        order = build_order(@venue.id, @side, :ioc, action: :unfilled)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_ioc_unfilled" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

          assert %NewOrders.Responses.CreateAccepted{} = order_response
          assert order_response.id != nil
          assert order_response.received_at != nil
        end
      end
    end)
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    venue = venue_id |> Atom.to_string()
    action = Keyword.fetch!(opts, :action)
    post_only = Keyword.get(opts, :post_only, false)

    struct(NewOrders.Order, %{
      client_id: Ecto.UUID.generate(),
      venue: venue,
      credential: "main",
      venue_product_symbol: venue |> venue_product_symbol,
      product_symbol: venue |> product_symbol,
      side: side,
      price: venue |> price(side, time_in_force, action),
      qty: venue |> qty(side, time_in_force, action),
      type: :limit,
      time_in_force: time_in_force,
      post_only: post_only
    })
  end

  defp venue_product_symbol("bitmex"), do: "XBTH19"
  defp venue_product_symbol("ftx"), do: "BTC/USD"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol("bitmex"), do: "xbth19"
  defp product_symbol("ftx"), do: :"btc/usd"
  defp product_symbol(_), do: "ltc_btc"

  defp price("bitmex", :buy, :ioc, :filled), do: Decimal.new("4455.5")
  defp price("bitmex", :sell, :ioc, :filled), do: Decimal.new("3785.5")
  defp price("bitmex", :buy, :ioc, :partially_filled), do: Decimal.new("4458.5")
  defp price("bitmex", :sell, :ioc, :partially_filled), do: Decimal.new("3749.5")
  defp price("bitmex", :buy, :ioc, :unfilled), do: Decimal.new("4450.5")
  defp price("bitmex", :sell, :ioc, :unfilled), do: Decimal.new("3755.5")
  defp price("ftx", :buy, :ioc, :unfilled), do: Decimal.new("25000.5")
  defp price("ftx", :sell, :ioc, :unfilled), do: Decimal.new("75000.5")
  defp price("bitmex", :buy, _, _), do: Decimal.new("10000.5")
  defp price("bitmex", :sell, _, _), do: Decimal.new("1000.5")
  defp price(_, :buy, _, _), do: Decimal.new("0.007")
  defp price(_, :sell, _, _), do: Decimal.new("0.1")

  defp qty("bitmex", _, :ioc, :partially_filled), do: Decimal.new(150)
  defp qty("bitmex", _, :ioc, _), do: Decimal.new(10)
  defp qty("bitmex", :buy, _, _), do: Decimal.new(1)
  defp qty("bitmex", :sell, _, _), do: Decimal.new(1)
  defp qty("ftx", _, _, :unfilled), do: Decimal.new("0.0001")
  defp qty(_, :buy, _, _), do: Decimal.new("0.2")
  defp qty(_, :sell, _, _), do: Decimal.new("0.1")
end
