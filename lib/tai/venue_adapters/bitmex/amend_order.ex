defmodule Tai.VenueAdapters.Bitmex.AmendOrder do
  def amend_order(venue_order_id, attrs, %{api_key: api_key, api_secret: api_secret}) do
    params = to_params(attrs, venue_order_id)

    %ExBitmex.Credentials{api_key: api_key, api_secret: api_secret}
    |> ExBitmex.Rest.Orders.amend(params)
    |> parse_response()
  end

  def to_params(attrs, venue_order_id) do
    params = %{}

    params =
      if price = Map.get(attrs, :price) do
        Map.put(params, :price, price)
      else
        params
      end

    params =
      if qty = Map.get(attrs, :qty) do
        Map.put(params, :leavesQty, qty)
      else
        params
      end

    Map.put(params, :orderID, venue_order_id)
  end

  defp parse_response({:ok, %ExBitmex.Order{} = order, %ExBitmex.RateLimit{} = _rate_limit}) do
    response = %Tai.Trading.OrderResponse{
      id: order.order_id,
      status: order.ord_status |> from_venue_status(),
      time_in_force: :gtc,
      original_size: Decimal.new(order.order_qty),
      # cumulative_qty: Decimal.new(order.cum_qty),
      cumulative_qty: Decimal.new(0),
      remaining_qty: Decimal.new(order.leaves_qty)
    }

    {:ok, response}
  end

  defp from_venue_status("New"), do: :open
end
