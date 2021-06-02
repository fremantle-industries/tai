defmodule Tai.VenueAdapters.Ftx.CancelOrder do
  @moduledoc """
  Sends a cancel order request to FTX
  """

  alias Tai.NewOrders

  @type order :: NewOrders.Order.t()
  @type credentials :: Tai.Venues.Adapter.credentials()
  @type response :: NewOrders.Responses.CancelAccepted.t()
  @type reason :: term

  @spec cancel_order(order, credentials) :: {:ok, response} | {:error, reason}
  def cancel_order(order, credentials) do
    ExFtx.Credentials
    |> struct!(credentials)
    |> send_to_venue(order.client_id)
    |> parse_response(order.venue_order_id)
  end

  defp send_to_venue(credentials, client_id) do
    ExFtx.Orders.CancelByClientOrderId.delete(credentials, client_id)
  end

  defp parse_response(:ok, venue_order_id) do
    received_at = Tai.Time.monotonic_time()
    response = %NewOrders.Responses.CancelAccepted{id: venue_order_id, received_at: received_at}
    {:ok, response}
  end

  defp parse_response({:error, "Order not found"}, _venue_order_id) do
    {:error, :not_found}
  end

  defp parse_response({:error, "Order already closed"}, _venue_order_id) do
    {:error, :already_closed}
  end

  defp parse_response({:error, "Order already queued for cancellation"}, _venue_order_id) do
    {:error, :already_queued_for_cancelation}
  end
end
