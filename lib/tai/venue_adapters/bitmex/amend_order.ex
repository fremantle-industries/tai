defmodule Tai.VenueAdapters.Bitmex.AmendOrder do
  import Tai.VenueAdapters.Bitmex.OrderStatus

  @type credentials :: Tai.Venues.Adapter.credentials()
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type attrs :: Tai.Trading.Orders.Amend.attrs()
  @type response :: Tai.Trading.OrderResponses.Amend.t()
  @type reason ::
          :timeout
          | :overloaded
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec amend_order(venue_order_id, attrs, credentials) :: {:ok, response} | {:error, reason}
  def amend_order(venue_order_id, attrs, credentials) do
    params = to_params(attrs, venue_order_id)

    credentials
    |> to_venue_credentials
    |> amend_on_venue(params)
    |> parse_response()
  end

  defdelegate amend_on_venue(credentials, params),
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

  defp parse_response({
         :ok,
         %ExBitmex.Order{} = venue_order,
         %ExBitmex.RateLimit{} = _rate_limit
       }) do
    {:ok, venue_timestamp, 0} = DateTime.from_iso8601(venue_order.timestamp)

    response = %Tai.Trading.OrderResponses.Amend{
      id: venue_order.order_id,
      status: venue_order.ord_status |> from_venue_status(:ignore),
      price: Tai.Utils.Decimal.from(venue_order.price),
      leaves_qty: Decimal.new(venue_order.leaves_qty),
      cumulative_qty: Decimal.new(venue_order.cum_qty),
      received_at: Timex.now(),
      venue_timestamp: venue_timestamp
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}), do: {:error, :timeout}
  defp parse_response({:error, {:nonce_not_increasing, _} = reason, _}), do: {:error, reason}
  defp parse_response({:error, :overloaded = reason, _}), do: {:error, reason}
  defp parse_response({:error, reason, _}), do: {:error, {:unhandled, reason}}
end
