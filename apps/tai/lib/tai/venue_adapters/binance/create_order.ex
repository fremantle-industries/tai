defmodule Tai.VenueAdapters.Binance.CreateOrder do
  @moduledoc """
  Create orders for the Binance adapter
  """

  @limit "LIMIT"

  def create_order(%Tai.Orders.Order{side: side, type: :limit} = order, credentials) do
    venue_time_in_force = order.time_in_force |> to_venue_time_in_force
    venue_side = side |> Atom.to_string() |> String.upcase()
    credentials = struct!(ExBinance.Credentials, credentials)

    %ExBinance.Rest.Requests.CreateOrderRequest{
      new_client_order_id: order.client_id,
      symbol: order.venue_product_symbol,
      side: venue_side,
      type: @limit,
      quantity: order.qty,
      quote_order_qty: order.qty,
      price: order.price,
      time_in_force: venue_time_in_force
    }
    |> ExBinance.Private.create_order(credentials)
    |> parse_response(order)
  end

  defp to_venue_time_in_force(:gtc), do: "GTC"
  defp to_venue_time_in_force(:fok), do: "FOK"
  defp to_venue_time_in_force(:ioc), do: "IOC"

  defp parse_response(
         {:ok, %ExBinance.Rest.Responses.CreateOrderResponse{} = binance_response},
         _
       ) do
    received_at = Tai.Time.monotonic_time()
    venue_timestamp = binance_response.transact_time |> DateTime.from_unix!(:millisecond)
    venue_order_id = binance_response.order_id |> Integer.to_string()

    response = %Tai.Orders.Responses.CreateAccepted{
      id: venue_order_id,
      venue_timestamp: venue_timestamp,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout} = error, _) do
    error
  end

  defp parse_response({:error, :connect_timeout} = error, _) do
    error
  end

  defp parse_response({:error, {:insufficient_balance, _}}, _) do
    {:error, :insufficient_balance}
  end

  defp parse_response({:error, reason}, _) do
    {:error, {:unhandled, reason}}
  end
end
