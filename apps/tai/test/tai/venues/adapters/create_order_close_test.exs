defmodule Tai.Venues.Adapters.CreateOrderCloseTest do
  use Tai.TestSupport.DataCase, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias Tai.NewOrders

  setup_all do
    HTTPoison.start()
  end

  @sides [:buy, :sell]

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_close()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      test "#{venue.id} #{side} returns an error when there is an insufficient open position" do
        order = build_order(@venue.id, @side, :gtc, post_only: false, action: :unfilled)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_close_insufficient_position" do
          assert {:error, :insufficient_position} = Tai.Venues.Client.create_order(order)
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
      product_symbol: venue |> product_symbol,
      product_type: venue |> product_type,
      side: side,
      price: venue |> price(side, time_in_force, action),
      qty: venue |> qty(side, time_in_force, action),
      type: :limit,
      time_in_force: time_in_force,
      post_only: post_only,
      close: true
    })
  end

  defp product_symbol("okex_futures"), do: "eth_usd_190628"
  defp product_symbol("okex_swap"), do: "eth_usd_swap"

  defp product_type("okex_swap"), do: :swap
  defp product_type(_), do: :future

  defp price("okex_futures", :buy, :gtc, _), do: Decimal.new("70.5")
  defp price("okex_futures", :sell, :gtc, _), do: Decimal.new("290.5")
  defp price("okex_swap", :buy, :gtc, _), do: Decimal.new("70.5")
  defp price("okex_swap", :sell, :gtc, _), do: Decimal.new("290.5")

  defp qty("okex_futures", :buy, _, _), do: Decimal.new(1)
  defp qty("okex_futures", :sell, _, _), do: Decimal.new(1)
  defp qty("okex_swap", :buy, _, _), do: Decimal.new(1)
  defp qty("okex_swap", :sell, _, _), do: Decimal.new(1)
end
