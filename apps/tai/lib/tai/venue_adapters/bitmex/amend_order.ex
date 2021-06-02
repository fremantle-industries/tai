defmodule Tai.VenueAdapters.Bitmex.AmendOrder do
  alias Tai.NewOrders

  @type credentials :: Tai.Venues.Adapter.credentials()
  @type order :: NewOrders.Order.t()
  @type attrs :: NewOrders.Worker.amend_attrs()
  @type response :: NewOrders.Responses.AmendAccepted.t()
  @type reason ::
          :timeout
          | :overloaded
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec amend_order(order, attrs, credentials) :: {:ok, response} | {:error, reason}
  def amend_order(order, attrs, credentials) do
    params = to_params(attrs, order.venue_order_id)

    credentials
    |> to_venue_credentials
    |> send_to_venue(params)
    |> parse_response()
  end

  defdelegate send_to_venue(credentials, params),
    to: ExBitmex.Rest.Orders,
    as: :amend

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  defp to_params(attrs, venue_order_id) do
    attrs
    |> Enum.reduce(
      %{},
      fn
        {:price, v}, p -> p |> Map.put(:price, v)
        {:qty, v}, p -> p |> Map.put(:leavesQty, v)
        _, p -> p
      end
    )
    |> Map.put(:orderID, venue_order_id)
  end

  defp parse_response({:ok, venue_order, _rate_limit}) do
    {:ok, venue_timestamp, 0} = DateTime.from_iso8601(venue_order.timestamp)
    received_at = Tai.Time.monotonic_time()
    response = %NewOrders.Responses.AmendAccepted{id: venue_order.order_id, received_at: received_at, venue_timestamp: venue_timestamp}
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
