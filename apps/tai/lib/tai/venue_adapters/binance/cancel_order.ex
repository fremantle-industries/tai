defmodule Tai.VenueAdapters.Binance.CancelOrder do
  alias Tai.Orders.Responses
  alias ExBinance.Spot.Private

  def cancel_order(order, credentials) do
    venue_credentials = struct!(ExBinance.Credentials, credentials)

    order.venue_product_symbol
    |> send_to_venue(order.venue_order_id, venue_credentials)
    |> parse_response()
  end

  defdelegate send_to_venue(venue_symbol, order_id, credentials),
    to: ExBinance.Spot.Private,
    as: :cancel_order_by_order_id

  defp parse_response({:ok, %Private.Responses.CancelOrderResponse{} = venue_response}) do
    received_at = Tai.Time.monotonic_time()

    response = %Responses.CancelAccepted{
      id: venue_response.order_id,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:error, {:not_found, _}}) do
    {:error, :not_found}
  end

  defp parse_response({:error, reason}) do
    {:error, {:unhandled, reason}}
  end
end
