defmodule Tai.VenueAdapters.OkEx.CancelOrder do
  @moduledoc """
  Sends a cancel order request to OkEx.

  OkEx uses different API endpoints for each of their
  product types: futures, swap & spot.  API responses
  across these products are inconsistent.
  """

  alias Tai.NewOrders

  @type order :: NewOrders.Order.t()
  @type credentials :: Tai.Venues.Adapter.credentials()
  @type response :: NewOrders.Responses.CancelAccepted.t()
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
    {mod.cancel_orders(venue_symbol, [order.venue_order_id], %{}, venue_config), order}
  end

  defp module_for(%NewOrders.Order{product_type: :future}), do: ExOkex.Futures.Private
  defp module_for(%NewOrders.Order{product_type: :swap}), do: ExOkex.Swap.Private
  defp module_for(%NewOrders.Order{product_type: :spot}), do: ExOkex.Spot.Private

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.OkEx.Credentials,
    as: :from

  defp parse_response({{:ok, %{"result" => true, "order_ids" => [order_id | _]}}, _order}) do
    received_at = Tai.Time.monotonic_time()
    response = %NewOrders.Responses.CancelAccepted{id: order_id, received_at: received_at}
    {:ok, response}
  end

  defp parse_response({{:ok, %{"result" => "true", "ids" => [order_id | _]}}, _order}) do
    received_at = Tai.Time.monotonic_time()
    response = %NewOrders.Responses.CancelAccepted{id: order_id, received_at: received_at}
    {:ok, response}
  end

  defp parse_response({{:ok, response}, %NewOrders.Order{product_type: :spot}}) do
    response
    |> Map.values()
    |> List.flatten()
    |> parse_spot_response()
  end

  defp parse_response({{:ok, %{"result" => false, "error_message" => "error order_ids"}}, _order}) do
    {:error, :not_found}
  end

  defp parse_response({{:ok, %{"result" => "false"}}, _order}) do
    {:error, :not_found}
  end

  defp parse_response({{:error, :timeout}, _order}) do
    {:error, :timeout}
  end

  defp parse_response({{:error, :connect_timeout}, _order}) do
    {:error, :connect_timeout}
  end

  defp parse_spot_response([%{"result" => true, "error_code" => "0", "order_id" => order_id} | _]) do
    received_at = Tai.Time.monotonic_time()
    response = %NewOrders.Responses.CancelAccepted{id: order_id, received_at: received_at}
    {:ok, response}
  end
end
