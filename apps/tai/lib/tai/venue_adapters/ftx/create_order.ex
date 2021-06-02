defmodule Tai.VenueAdapters.Ftx.CreateOrder do
  @moduledoc """
  Create orders for the FTX adapter
  """

  alias Tai.{Orders, NewOrders}

  def create_order(%Orders.Order{type: :limit} = order, credentials) do
    venue_side = order.side |> to_venue_side()
    venue_ioc = order.time_in_force |> to_venue_ioc()
    venue_price = order.price |> Decimal.to_float()
    venue_size = order.qty |> Decimal.to_float()
    credentials = struct!(ExFtx.Credentials, credentials)

    venue_payload = %ExFtx.OrderPayload{
      client_id: order.client_id,
      market: order.venue_product_symbol,
      side: venue_side,
      price: venue_price,
      size: venue_size,
      type: "limit",
      reduce_only: false,
      ioc: venue_ioc,
      post_only: order.post_only
    }

    credentials
    |> ExFtx.Orders.Create.post(venue_payload)
    |> parse_response(order)
  end

  def create_order(%NewOrders.Order{type: :limit} = order, credentials) do
    venue_side = order.side |> to_venue_side()
    venue_ioc = order.time_in_force |> to_venue_ioc()
    venue_price = order.price |> Decimal.to_float()
    venue_size = order.qty |> Decimal.to_float()
    credentials = struct!(ExFtx.Credentials, credentials)

    venue_payload = %ExFtx.OrderPayload{
      client_id: order.client_id,
      market: order.venue_product_symbol,
      side: venue_side,
      price: venue_price,
      size: venue_size,
      type: "limit",
      reduce_only: false,
      ioc: venue_ioc,
      post_only: order.post_only
    }

    credentials
    |> ExFtx.Orders.Create.post(venue_payload)
    |> parse_response(order)
  end

  defp to_venue_side(side), do: side |> Atom.to_string()

  defp to_venue_ioc(time_in_force), do: time_in_force == :ioc

  @date_format "{ISO:Extended}"
  defp parse_response({:ok, %ExFtx.Order{status: "new"} = venue_order}, %Orders.Order{}) do
    received_at = Tai.Time.monotonic_time()
    venue_order_id = venue_order.id
    venue_timestamp = venue_order.created_at |> Timex.parse!(@date_format)

    response = %Orders.Responses.CreateAccepted{
      id: venue_order_id,
      venue_timestamp: venue_timestamp,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:ok, %ExFtx.Order{status: "new"} = venue_order}, %NewOrders.Order{}) do
    received_at = Tai.Time.monotonic_time()
    venue_order_id = venue_order.id |> Integer.to_string()
    venue_timestamp = venue_order.created_at |> Timex.parse!(@date_format)

    response = %NewOrders.Responses.CreateAccepted{
      id: venue_order_id,
      venue_timestamp: venue_timestamp,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:error, "Size too small for provide"}, _), do: {:error, :size_too_small}

  defp parse_response({:error, reason}, _), do: {:error, {:unhandled, reason}}
end
