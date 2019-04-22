defmodule Tai.VenueAdapters.Bitmex.CancelOrder do
  import Tai.VenueAdapters.Bitmex.OrderStatus

  @type venue_order_id :: String.t()
  @type credentials :: map
  @type response :: Tai.Trading.OrderResponses.Cancel.t()
  @type reason ::
          :timeout
          | :overloaded
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec cancel_order(venue_order_id, credentials) :: {:ok, response} | {:error, reason}
  def cancel_order(venue_order_id, credentials) do
    credentials
    |> to_venue_credentials
    |> cancel_on_venue(%{orderID: venue_order_id})
    |> parse_response()
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  defdelegate cancel_on_venue(credentials, params),
    to: ExBitmex.Rest.Orders,
    as: :cancel

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

  defp parse_response({:error, :timeout, nil}), do: {:error, :timeout}
  defp parse_response({:error, :connect_timeout, nil}), do: {:error, :connect_timeout}
  defp parse_response({:error, :overloaded, _}), do: {:error, :overloaded}
  defp parse_response({:error, :rate_limited, _}), do: {:error, :rate_limited}
  defp parse_response({:error, {:nonce_not_increasing, _} = reason, _}), do: {:error, reason}
  defp parse_response({:error, reason, _}), do: {:error, {:unhandled, reason}}
end
