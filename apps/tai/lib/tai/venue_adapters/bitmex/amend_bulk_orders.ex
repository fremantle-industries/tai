defmodule Tai.VenueAdapters.Bitmex.AmendBulkOrders do
  alias Tai.Orders.Responses

  @type credentials :: Tai.Venues.Adapter.credentials()
  @type order :: Tai.Orders.Order.t()
  @type attrs :: Tai.Orders.Worker.amend_attrs()
  @type response :: Responses.AmendBulk.t()
  @type reason ::
          :timeout
          | :overloaded
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec amend_bulk_orders([{order, attrs}], credentials) :: {:ok, response} | {:error, reason}
  def amend_bulk_orders(orders_with_attrs, credentials) do
    bulk_params = to_bulk_params(orders_with_attrs)

    credentials
    |> to_venue_credentials
    |> send_to_venue(%{orders: bulk_params})
    |> parse_response()
  end

  defdelegate send_to_venue(credentials, params),
    to: ExBitmex.Rest.Orders,
    as: :amend_bulk

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  defp to_bulk_params(orders_with_attrs) do
    orders_with_attrs
    |> Enum.map(fn {order, attrs} ->
      to_params(attrs, order.venue_order_id)
    end)
  end

  defp to_params(attrs, venue_order_id) do
    attrs
    |> Enum.reduce(
      %{},
      fn
        {:price, v}, p -> p |> Map.put(:price, Decimal.to_float(v))
        {:qty, v}, p -> p |> Map.put(:leavesQty, Decimal.to_float(v))
        _, p -> p
      end
    )
    |> Map.put(:orderID, venue_order_id)
  end

  defp parse_response({:ok, venue_orders, _rate_limit}) do
    bulk_responses = parse_bulk_responses(venue_orders)
    response = %Responses.AmendBulk{orders: bulk_responses}
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

  defp parse_bulk_responses(venue_orders) do
    venue_orders
    |> Enum.map(fn venue_order ->
      {:ok, venue_timestamp, 0} = DateTime.from_iso8601(venue_order.timestamp)
      received_at = Tai.Time.monotonic_time()

      %Responses.AmendAccepted{
        id: venue_order.order_id,
        received_at: received_at,
        venue_timestamp: venue_timestamp
      }
    end)
  end
end
