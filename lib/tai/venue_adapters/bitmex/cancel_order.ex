defmodule Tai.VenueAdapters.Bitmex.CancelOrder do
  import Tai.VenueAdapters.Bitmex.OrderStatus

  @type venue_order_id :: String.t()
  @type credentials :: map
  @type response :: Tai.Trading.OrderResponses.Cancel.t()
  @type error_reason ::
          :not_implemented
          | :not_found
          | :timeout
          | Tai.CredentialError.t()

  @spec cancel_order(venue_order_id, credentials) :: {:ok, response} | {:error, error_reason}
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
    {:ok, venue_updated_at, 0} = DateTime.from_iso8601(venue_order.timestamp)

    response = %Tai.Trading.OrderResponses.Cancel{
      id: venue_order.order_id,
      status: venue_order.ord_status |> from_venue_status(:ignore),
      leaves_qty: Decimal.new(venue_order.leaves_qty),
      venue_updated_at: venue_updated_at
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}) do
    {:error, :timeout}
  end
end
