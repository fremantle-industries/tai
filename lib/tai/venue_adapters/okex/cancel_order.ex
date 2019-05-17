defmodule Tai.VenueAdapters.OkEx.CancelOrder do
  alias Tai.VenueAdapters.OkEx.Products
  alias Tai.Trading.OrderResponses.CancelAccepted

  @type order :: Tai.Trading.Order.t()
  @type credentials :: Tai.Venues.Adapter.credentials()
  @type response :: CancelAccepted.t()
  @type reason :: term

  @spec cancel_order(order, credentials) :: {:ok, response} | {:error, reason}
  def cancel_order(order, credentials) do
    {order, credentials}
    |> send_to_venue()
    |> parse_response()
  end

  def send_to_venue({order, credentials}) do
    venue_config = credentials |> to_venue_credentials
    venue_symbol = order.product_symbol |> Products.from_symbol()
    mod = order |> module_for()
    mod.cancel_orders(venue_symbol, [order.venue_order_id], %{}, venue_config)
  end

  defp module_for(%Tai.Trading.Order{product_type: :future}), do: ExOkex.Futures.Private
  defp module_for(%Tai.Trading.Order{product_type: :swap}), do: ExOkex.Swap.Private

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.OkEx.Credentials,
    as: :from

  defp parse_response({:ok, %{"order_ids" => [order_id | _]}}) do
    response = %CancelAccepted{id: order_id, received_at: Timex.now()}
    {:ok, response}
  end

  defp parse_response({:ok, %{"ids" => [order_id | _]}}) do
    response = %CancelAccepted{id: order_id, received_at: Timex.now()}
    {:ok, response}
  end

  defp parse_response({:error, :timeout}), do: {:error, :timeout}
  defp parse_response({:error, :connect_timeout}), do: {:error, :connect_timeout}
  # defp parse_response({:error, :overloaded, do: {:error, :overloaded}
  # defp parse_response({:error, :rate_limited, do: {:error, :rate_limited}
  # defp parse_response({:error, reason, do: {:error, {:unhandled, reason}}
end
