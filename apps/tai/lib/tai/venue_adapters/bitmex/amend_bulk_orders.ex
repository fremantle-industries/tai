defmodule Tai.VenueAdapters.Bitmex.AmendBulkOrders do
  import Tai.VenueAdapters.Bitmex.OrderStatus
  alias Tai.Orders

  @type credentials :: Tai.Venues.Adapter.credentials()
  @type order :: Orders.Order.t()
  @type attrs :: Orders.Worker.amend_attrs()
  @type response :: Orders.Responses.Amend.t()
  @type reason ::
          :timeout
          | :overloaded
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec amend_bulk_orders([{order, attrs}], credentials) :: {:ok, response} | {:error, reason}
  def amend_bulk_orders(orders_with_attrs, credentials) do
    params =
      orders_with_attrs
      |> Enum.map(fn {order, attrs} ->
        to_params(attrs, order.venue_order_id)
      end)

    credentials
    |> to_venue_credentials
    |> send_to_venue(%{orders: params})
    |> parse_response()
  end

  defdelegate send_to_venue(credentials, params),
    to: ExBitmex.Rest.Orders,
    as: :amend_bulk

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

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

  defp parse_response({
         :ok,
         venue_orders,
         %ExBitmex.RateLimit{} = _rate_limit
       }) do
    responses =
      Enum.map(venue_orders, fn venue_order ->
        {:ok, venue_timestamp, 0} = DateTime.from_iso8601(venue_order.timestamp)
        received_at = Tai.Time.monotonic_time()

        %Orders.Responses.Amend{
          id: venue_order.order_id,
          status: venue_order.ord_status |> from_venue_status(:ignore),
          price: Tai.Utils.Decimal.cast!(venue_order.price),
          leaves_qty: Decimal.new(venue_order.leaves_qty),
          cumulative_qty: Decimal.new(venue_order.cum_qty),
          received_at: received_at,
          venue_timestamp: venue_timestamp
        }
      end)

    response = %Orders.Responses.AmendBulk{orders: responses}
    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}), do: {:error, :timeout}
  defp parse_response({:error, :connect_timeout, nil}), do: {:error, :connect_timeout}
  defp parse_response({:error, :overloaded, _}), do: {:error, :overloaded}
  defp parse_response({:error, :rate_limited, _}), do: {:error, :rate_limited}
  defp parse_response({:error, {:nonce_not_increasing, _} = reason, _}), do: {:error, reason}
  defp parse_response({:error, reason, _}), do: {:error, {:unhandled, reason}}
end
