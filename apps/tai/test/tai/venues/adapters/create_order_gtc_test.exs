defmodule Tai.Venues.Adapters.CreateOrderGtcTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.Orders.Responses

  setup_all do
    HTTPoison.start()
  end

  @sides [:buy, :sell]

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_gtc_accepted()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      test "#{venue.id} #{side} limit unfilled accepted" do
        order = build_order(@venue.id, @side, :gtc, post_only: false)

        # TODO: Make sure this covers all cassettes in the correct location. It seems like this should really be renamed unfilled -> accepted
        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_gtc_unfilled" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

          assert %Responses.CreateAccepted{} = order_response
          assert order_response.id != nil
          assert order_response.received_at != nil
        end
      end
    end)
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    venue = venue_id |> Atom.to_string()
    post_only = Keyword.get(opts, :post_only, false)

    struct(Tai.Orders.Order, %{
      client_id: Ecto.UUID.generate(),
      venue: venue,
      credential: "main",
      venue_product_symbol: venue |> venue_product_symbol,
      product_symbol: venue |> product_symbol,
      product_type: venue |> product_type,
      side: side,
      price: venue |> price(side, time_in_force),
      qty: venue |> qty(side, time_in_force),
      type: :limit,
      time_in_force: time_in_force,
      post_only: post_only
    })
  end

  defp venue_product_symbol("bitmex"), do: "XBTH19"
  defp venue_product_symbol("okex_futures"), do: "ETH-USD-190628"
  defp venue_product_symbol("okex_swap"), do: "ETH-USD-SWAP"
  defp venue_product_symbol("okex_spot"), do: "ETH-USDT"
  defp venue_product_symbol("ftx"), do: "BTC/USD"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol("bitmex"), do: "xbth19"
  defp product_symbol("okex_futures"), do: "eth_usd_190628"
  defp product_symbol("okex_swap"), do: "eth_usd_swap"
  defp product_symbol("okex_spot"), do: "eth_usdt"
  defp product_symbol("ftx"), do: :"btc/usd"
  defp product_symbol(_), do: "ltc_btc"

  defp product_type("okex_swap"), do: :swap
  defp product_type("okex_spot"), do: :spot
  defp product_type(_), do: :future

  defp price("bitmex", :buy, :gtc), do: Decimal.new("100.5")
  defp price("bitmex", :sell, :gtc), do: Decimal.new("50000.5")
  defp price("okex_futures", :buy, :gtc), do: Decimal.new("70.5")
  defp price("okex_futures", :sell, :gtc), do: Decimal.new("290.5")
  defp price("okex_swap", :buy, :gtc), do: Decimal.new("70.5")
  defp price("okex_swap", :sell, :gtc), do: Decimal.new("290.5")
  defp price("okex_spot", :buy, :gtc), do: Decimal.new("70.5")
  defp price("okex_spot", :sell, :gtc), do: Decimal.new("290.5")
  defp price("ftx", :buy, :gtc), do: Decimal.new("25000.5")
  defp price("ftx", :sell, :gtc), do: Decimal.new("75000.5")
  defp price(_, :buy, _), do: Decimal.new("0.007")
  defp price(_, :sell, _), do: Decimal.new("0.1")

  defp qty("bitmex", :buy, _), do: Decimal.new(1)
  defp qty("bitmex", :sell, _), do: Decimal.new(1)
  defp qty("okex_futures", :buy, _), do: Decimal.new(1)
  defp qty("okex_futures", :sell, _), do: Decimal.new(1)
  defp qty("okex_swap", :buy, _), do: Decimal.new(1)
  defp qty("okex_swap", :sell, _), do: Decimal.new(1)
  defp qty("okex_spot", :buy, _), do: Decimal.new(1)
  defp qty("okex_spot", :sell, _), do: Decimal.new(1)
  defp qty("ftx", :buy, :gtc), do: Decimal.new("0.0001")
  defp qty("ftx", :sell, :gtc), do: Decimal.new("0.0001")
  defp qty(_, _, :gtc), do: Decimal.new(1_000)
  defp qty(_, :buy, _), do: Decimal.new("0.2")
  defp qty(_, :sell, _), do: Decimal.new("0.1")
end
