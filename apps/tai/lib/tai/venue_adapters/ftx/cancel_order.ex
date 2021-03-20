defmodule Tai.VenueAdapters.Ftx.CancelOrder do
  @moduledoc """
  Sends a cancel order request to FTX
  """

  alias Tai.Trading.{Order, OrderResponses}

  @type order :: Order.t()
  @type credentials :: Tai.Venues.Adapter.credentials()
  @type response :: OrderResponses.CancelAccepted.t()
  @type reason :: term

  @spec cancel_order(order, credentials) :: {:ok, response} | {:error, reason}
  def cancel_order(order, credentials) do
    ExFtx.Credentials
    |> struct!(credentials)
    |> send_to_venue(order.venue_order_id)
    |> parse_response(order.venue_order_id)
  end

  defp send_to_venue(credentials, venue_order_id) do
    ExFtx.Orders.CancelByOrderId.delete(credentials, venue_order_id)
  end

  defp parse_response(:ok, venue_order_id) do
    received_at = Timex.now()
    response = %OrderResponses.CancelAccepted{id: venue_order_id, received_at: received_at}
    {:ok, response}
  end
end
