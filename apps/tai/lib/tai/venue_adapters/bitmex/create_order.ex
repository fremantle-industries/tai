defmodule Tai.VenueAdapters.Bitmex.CreateOrder do
  @moduledoc """
  Create orders for the Bitmex adapter
  """

  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.Orders.Responses

  @type credentials :: Tai.Venues.Adapter.credentials()
  @type order :: Tai.Orders.Order.t()
  @type response :: Responses.CreateAccepted.t()
  @type reason ::
          :timeout
          | :connect_timeout
          | :overloaded
          | :insufficient_balance
          | {:nonce_not_increasing, msg :: String.t()}
          | {:unhandled, term}

  @spec create_order(order, credentials) :: {:ok, response} | {:error, reason}
  def create_order(%Tai.Orders.Order{} = order, credentials) do
    params = build_params(order)

    credentials
    |> to_venue_credentials
    |> send_to_venue(params)
    |> parse_response(order)
  end

  @limit "Limit"
  defp build_params(order) do
    venue_client_order_id = ClientId.to_venue(order.client_id, order.time_in_force)

    params = %{
      clOrdID: venue_client_order_id,
      side: order.side |> to_venue_side,
      ordType: @limit,
      symbol: order.venue_product_symbol,
      orderQty: order.qty,
      price: order.price,
      timeInForce: order.time_in_force |> to_venue_time_in_force
    }

    if order.post_only do
      params |> Map.put("execInst", "ParticipateDoNotInitiate")
    else
      params
    end
  end

  defdelegate send_to_venue(credentials, params),
    to: ExBitmex.Rest.Orders,
    as: :create

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Bitmex.Credentials,
    as: :from

  @buy "Buy"
  @sell "Sell"
  defp to_venue_side(:buy), do: @buy
  defp to_venue_side(:sell), do: @sell

  defp to_venue_time_in_force(:gtc), do: "GoodTillCancel"
  defp to_venue_time_in_force(:ioc), do: "ImmediateOrCancel"
  defp to_venue_time_in_force(:fok), do: "FillOrKill"

  @format "{ISO:Extended}"
  defp parse_response({:ok, venue_order, _rate_limit}, _order) do
    received_at = Tai.Time.monotonic_time()
    venue_timestamp = Timex.parse!(venue_order.timestamp, @format)

    response = %Responses.CreateAccepted{
      id: venue_order.order_id,
      venue_timestamp: venue_timestamp,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}, _) do
    {:error, :timeout}
  end

  defp parse_response({:error, :connect_timeout, nil}, _) do
    {:error, :connect_timeout}
  end

  defp parse_response({:error, :overloaded, _}, _) do
    {:error, :overloaded}
  end

  defp parse_response({:error, :rate_limited, _}, _) do
    {:error, :rate_limited}
  end

  defp parse_response({:error, {:nonce_not_increasing, _} = reason, _}, _) do
    {:error, reason}
  end

  defp parse_response({:error, {:insufficient_balance, _}, _}, _) do
    {:error, :insufficient_balance}
  end

  defp parse_response({:error, reason, _}, _) do
    {:error, {:unhandled, reason}}
  end
end
