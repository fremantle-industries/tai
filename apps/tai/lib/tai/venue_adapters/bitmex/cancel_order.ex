defmodule Tai.VenueAdapters.Bitmex.CancelOrder do
  alias Tai.NewOrders

  @type order :: NewOrders.Order.t()
  @type credentials :: map
  @type response :: NewOrders.Responses.CancelAccepted.t()
  @type reason ::
          :timeout
          | :overloaded
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec cancel_order(order, credentials) :: {:ok, response} | {:error, reason}
  def cancel_order(order, credentials) do
    credentials
    |> to_venue_credentials
    |> send_to_venue(%{orderID: order.venue_order_id})
    |> parse_response()
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  defdelegate send_to_venue(credentials, params),
    to: ExBitmex.Rest.Orders,
    as: :cancel

  defp parse_response({:ok, [venue_order | _], %ExBitmex.RateLimit{}}) do
    received_at = Tai.Time.monotonic_time()
    {:ok, venue_timestamp, 0} = DateTime.from_iso8601(venue_order.timestamp)

    response = %NewOrders.Responses.CancelAccepted{
      id: venue_order.order_id,
      received_at: received_at,
      venue_timestamp: venue_timestamp
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}) do
    {:error, :timeout}
  end

  defp parse_response({:error, :connect_timeout, nil}) do
    {:error, :connect_timeout}
  end

  defp parse_response({:error, :overloaded, _}) do
    {:error, :overloaded}
  end

  defp parse_response({:error, :rate_limited, _}) do
    {:error, :rate_limited}
  end

  defp parse_response({:error, {:nonce_not_increasing, _} = reason, _}) do
    {:error, reason}
  end

  defp parse_response({:error, reason, _}) do
    {:error, {:unhandled, reason}}
  end
end
