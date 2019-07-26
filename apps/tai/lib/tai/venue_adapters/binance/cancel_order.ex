defmodule Tai.VenueAdapters.Binance.CancelOrder do
  alias Tai.VenueAdapters.Binance.OrderStatus

  def cancel_order(order, credentials) do
    venue_credentials = struct!(ExBinance.Credentials, credentials)

    order.product_symbol
    |> to_venue_symbol()
    |> send_to_venue(order.venue_order_id, venue_credentials)
    |> parse_response()
  end

  defdelegate to_venue_symbol(product_symbol),
    to: Tai.VenueAdapters.Binance.Products,
    as: :to_symbol

  defdelegate send_to_venue(venue_symbol, order_id, credentials),
    to: ExBinance.Private,
    as: :cancel_order_by_order_id

  defp parse_response({:ok, %ExBinance.Responses.CancelOrder{} = venue_response}) do
    response = %Tai.Trading.OrderResponses.Cancel{
      id: venue_response.order_id,
      status: venue_response.status |> OrderStatus.from_venue(),
      leaves_qty: Decimal.new(0)
    }

    {:ok, response}
  end

  defp parse_response({:error, {:not_found, _}}), do: {:error, :not_found}
  defp parse_response({:error, reason}), do: {:error, {:unhandled, reason}}
end
