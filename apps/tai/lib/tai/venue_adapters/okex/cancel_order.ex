defmodule Tai.VenueAdapters.OkEx.CancelOrder do
  @moduledoc """
  Sends a cancel order request to OkEx.

  OkEx uses different API endpoints for each of their
  product types: futures, swap & spot.  API responses
  across these products are inconsistent.
  """

  alias Tai.Trading.OrderResponses.CancelAccepted

  @type order :: Tai.Trading.Order.t()
  @type credentials :: Tai.Venues.Adapter.credentials()
  @type response :: CancelAccepted.t()
  @type reason :: :timeout | :connect_timeout | :not_found

  @spec cancel_order(order, credentials) :: {:ok, response} | {:error, reason}
  def cancel_order(order, credentials) do
    {order, credentials}
    |> send_to_venue()
    |> parse_response()
  end

  def send_to_venue({order, credentials}) do
    venue_config = credentials |> to_venue_credentials
    venue_symbol = order.venue_product_symbol
    mod = order |> module_for()
    mod.cancel_orders(venue_symbol, [order.venue_order_id], %{}, venue_config)
  end

  defp module_for(%Tai.Trading.Order{product_type: :future}), do: ExOkex.Futures.Private
  defp module_for(%Tai.Trading.Order{product_type: :swap}), do: ExOkex.Swap.Private

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.OkEx.Credentials,
    as: :from

  defp parse_response({:ok, %{"result" => true, "order_ids" => [order_id | _]}}) do
    response = %CancelAccepted{id: order_id, received_at: Timex.now()}
    {:ok, response}
  end

  defp parse_response({:ok, %{"result" => "true", "ids" => [order_id | _]}}) do
    response = %CancelAccepted{id: order_id, received_at: Timex.now()}
    {:ok, response}
  end

  defp parse_response({:ok, %{"result" => false, "error_message" => "error order_ids"}}) do
    {:error, :not_found}
  end

  defp parse_response({:ok, %{"result" => "false"}}) do
    {:error, :not_found}
  end

  defp parse_response({:error, :timeout}), do: {:error, :timeout}
  defp parse_response({:error, :connect_timeout}), do: {:error, :connect_timeout}
end
