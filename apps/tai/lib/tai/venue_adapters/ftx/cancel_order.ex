defmodule Tai.VenueAdapters.Ftx.CancelOrder do
  @moduledoc """
  Sends a cancel order request to FTX
  """

  alias Tai.Orders.Order
  alias Tai.Orders

  @type order :: Order.t()
  @type credentials :: Tai.Venues.Adapter.credentials()
  @type response :: Orders.Responses.CancelAccepted.t()
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
    response = %Orders.Responses.CancelAccepted{id: venue_order_id, received_at: received_at}
    {:ok, response}
  end
end
