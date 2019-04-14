defmodule Tai.VenueAdapters.OkEx.CancelOrder do
  alias Tai.VenueAdapters.OkEx.Products
  alias Tai.Trading.OrderResponses.CancelAccepted

  @type credentials :: Tai.Venues.Adapter.credentials()

  def cancel_order(order, credentials) do
    venue_config = credentials |> to_venue_credentials

    order.symbol
    |> Products.from_symbol()
    |> send_to_venue([order.venue_order_id], %{}, venue_config)
    |> parse_response()
  end

  defdelegate send_to_venue(instrument_id, order_ids, params, config),
    to: ExOkex.Futures.Private,
    as: :cancel_orders

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.OkEx.Credentials,
    as: :from

  defp parse_response({:ok, %{"result" => true, "order_ids" => [order_id | _]}}) do
    response = %CancelAccepted{id: order_id, received_at: Timex.now()}
    {:ok, response}
  end

  # defp parse_response({:error, :timeout, nil}), do: {:error, :timeout}
  # defp parse_response({:error, :connect_timeout, nil}), do: {:error, :connect_timeout}
  # defp parse_response({:error, :overloaded, _}), do: {:error, :overloaded}
  # defp parse_response({:error, :rate_limited, _}), do: {:error, :rate_limited}
  # defp parse_response({:error, reason, _}), do: {:error, {:unhandled, reason}}
end
