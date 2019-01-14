defmodule Tai.VenueAdapters.Bitmex.CreateOrder do
  @moduledoc """
  Create orders for the Bitmex adapter
  """

  import Tai.VenueAdapters.Bitmex.OrderStatus

  def create_order(%Tai.Trading.Order{} = order, credentials) do
    params = build_params(order)

    credentials
    |> to_bitmex_credentials
    |> ExBitmex.Rest.Orders.create(params)
    |> parse_response(order)
  end

  defp build_params(order) do
    params = %{
      side: order.side |> to_venue_side,
      ordType: "Limit",
      symbol: order.symbol |> to_venue_symbol,
      orderQty: order.qty,
      price: order.price,
      timeInForce: order.time_in_force |> to_venue_time_in_force
    }

    if order.post_only do
      Map.put(params, "execInst", "ParticipateDoNotInitiate")
    else
      params
    end
  end

  defp to_bitmex_credentials(attrs), do: struct!(ExBitmex.Credentials, attrs)

  @buy "Buy"
  @sell "Sell"
  defp to_venue_side(:buy), do: @buy
  defp to_venue_side(:sell), do: @sell

  defp to_venue_symbol(symbol) do
    symbol
    |> Atom.to_string()
    |> String.upcase()
  end

  defp to_venue_time_in_force(:gtc), do: "GoodTillCancel"
  defp to_venue_time_in_force(:ioc), do: "ImmediateOrCancel"
  defp to_venue_time_in_force(:fok), do: "FillOrKill"

  @format "{ISO:Extended}"
  defp parse_response(
         {:ok, %ExBitmex.Order{} = venue_order, %ExBitmex.RateLimit{}},
         order
       ) do
    avg_price =
      (venue_order.avg_px && Tai.Utils.Decimal.from(venue_order.avg_px)) || Decimal.new(0)

    response = %Tai.Trading.OrderResponses.Create{
      id: venue_order.order_id,
      status: venue_order.ord_status |> from_venue_status(order),
      avg_price: avg_price,
      original_size: Decimal.new(venue_order.order_qty),
      leaves_qty: Decimal.new(venue_order.leaves_qty),
      cumulative_qty: Decimal.new(venue_order.cum_qty),
      venue_created_at: Timex.parse!(venue_order.timestamp, @format)
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}, _), do: {:error, :timeout}

  defp parse_response({:error, {:insufficient_balance, _msg}, _}, _),
    do: {:error, :insufficient_balance}

  defp parse_response({:error, {:nonce_not_increasing, _} = reason, _}, _), do: {:error, reason}
end
