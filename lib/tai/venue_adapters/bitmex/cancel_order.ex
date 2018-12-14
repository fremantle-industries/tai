defmodule Tai.VenueAdapters.Bitmex.CancelOrder do
  def cancel_order(venue_order_id, credentials) do
    params = %{orderID: venue_order_id}

    credentials
    |> to_bitmex_credentials
    |> ExBitmex.Rest.Orders.cancel(params)
    |> parse_response()
  end

  defp to_bitmex_credentials(%{api_key: api_key, api_secret: api_secret}) do
    %ExBitmex.Credentials{api_key: api_key, api_secret: api_secret}
  end

  defp parse_response({:ok, [venue_order | _], %ExBitmex.RateLimit{}}) do
    response = %Tai.Trading.OrderResponse{
      id: venue_order.order_id,
      status: venue_order.ord_status |> from_venue_status(),
      time_in_force: :gtc,
      original_size: Decimal.new(venue_order.order_qty),
      executed_size: Decimal.new(venue_order.cum_qty)
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}) do
    {:error, :timeout}
  end

  defp from_venue_status("Canceled"), do: :canceled
end
