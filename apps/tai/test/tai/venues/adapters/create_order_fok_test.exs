defmodule Tai.Venues.Adapters.CreateOrderFokTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    HTTPoison.start()
  end

  @sides [:buy, :sell]

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_fok()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      describe "#{venue.id} #{side} limit fok" do
        test "filled" do
          order = build_order(@venue.id, @side, :fok, action: :filled)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_fok_filled" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert %Decimal{} = order_response.cumulative_qty
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == order_response.original_size
            assert order_response.status == :filled
            assert %DateTime{} = order_response.venue_timestamp
            assert %DateTime{} = order_response.received_at
          end
        end

        test "expired" do
          order = build_order(@venue.id, @side, :fok, action: :expired)

          use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_fok_expired" do
            assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

            assert order_response.id != nil
            assert %Decimal{} = order_response.original_size
            assert order_response.leaves_qty == Decimal.new(0)
            assert order_response.cumulative_qty == Decimal.new(0)
            assert order_response.status == :expired
            assert %DateTime{} = order_response.venue_timestamp
            assert %DateTime{} = order_response.received_at
          end
        end
      end
    end)
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    action = Keyword.fetch!(opts, :action)

    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      credential_id: :main,
      venue_product_symbol: venue_id |> venue_product_symbol,
      product_symbol: venue_id |> product_symbol,
      side: side,
      price: venue_id |> price(side, time_in_force, action),
      qty: venue_id |> qty(side, time_in_force, action),
      type: :limit,
      time_in_force: time_in_force,
      post_only: false
    })
  end

  defp venue_product_symbol(:bitmex), do: "XBTH19"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(_), do: :ltc_btc

  defp price(:bitmex, :buy, :fok, :filled), do: Decimal.new("4455.5")
  defp price(:bitmex, :sell, :fok, :filled), do: Decimal.new("3788.5")
  defp price(:bitmex, :buy, :fok, :expired), do: Decimal.new("4450.5")
  defp price(:bitmex, :sell, :fok, :expired), do: Decimal.new("3790.5")
  defp price(_, :buy, _, _), do: Decimal.new("0.007")
  defp price(_, :sell, _, _), do: Decimal.new("0.1")

  defp qty(:bitmex, _, :fok, _), do: Decimal.new(10)
  defp qty(_, :buy, _, _), do: Decimal.new("0.2")
  defp qty(_, :sell, _, _), do: Decimal.new("0.1")
end
