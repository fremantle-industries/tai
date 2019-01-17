defmodule Tai.VenueAdapters.Bitmex.AmendOrder do
  import Tai.VenueAdapters.Bitmex.OrderStatus

  @type credentials :: map
  @type venue_order_id :: String.t()
  @type attrs :: Tai.Trading.Orders.Amend.attrs()
  @type response :: Tai.Trading.OrderResponses.Amend.t()
  @type error_reason ::
          :timeout
          | {:nonce_not_increasing, String.t()}
          | Tai.CredentialError.t()

  @spec amend_order(venue_order_id, attrs, credentials) ::
          {:ok, response} | {:error, error_reason}
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

  defp parse_response({
         :ok,
         %ExBitmex.Order{} = venue_order,
         %ExBitmex.RateLimit{} = _rate_limit
       }) do
    {:ok, venue_updated_at, 0} = DateTime.from_iso8601(venue_order.timestamp)

    response = %Tai.Trading.OrderResponses.Amend{
      id: venue_order.order_id,
      status: venue_order.ord_status |> from_venue_status(:ignore),
      price: Tai.Utils.Decimal.from(venue_order.price),
      leaves_qty: Decimal.new(venue_order.leaves_qty),
      cumulative_qty: Decimal.new(venue_order.cum_qty),
      venue_updated_at: venue_updated_at
    }

    {:ok, response}
  end

  defp parse_response({:error, reason, _}), do: {:error, reason}
end
