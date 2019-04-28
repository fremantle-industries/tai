defmodule Tai.VenueAdapters.OkEx.CreateOrder do
  @moduledoc """
  Create orders for the OkEx adapter
  """

  alias Tai.VenueAdapters.OkEx.ClientId
  alias Tai.Trading.OrderResponses.CreateAccepted

  @type credentials :: Tai.Venues.Adapter.credentials()
  @type order :: Tai.Trading.Order.t()
  @type response :: CreateAccepted.t()
  # @type reason ::
  # :timeout
  # | :connect_timeout
  # | :insufficient_balance
  # | {:unhandled, term}
  @type reason :: term

  @spec create_order(order, credentials) :: {:ok, response} | {:error, reason}
  def create_order(%Tai.Trading.Order{} = order, credentials) do
    venue_config = credentials |> to_venue_credentials

    order
    |> build_params()
    |> send_to_venue(venue_config)
    |> parse_response()
  end

  defp build_params(order) do
    %{
      instrument_id: order.product_symbol |> to_venue_symbol,
      leverage: 20,
      orders_data: [
        %{
          client_oid: order.client_id |> ClientId.to_venue(),
          price: order.price |> to_decimal_string,
          size: order.qty |> to_decimal_string,
          type: order |> to_venue_type,
          order_type: order |> to_venue_order_type,
          match_price: 0
        }
      ]
    }
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.OkEx.Credentials,
    as: :from

  defdelegate to_venue_symbol(symbols),
    to: Tai.VenueAdapters.OkEx.Products,
    as: :from_symbol

  defp to_decimal_string(price), do: price |> Decimal.to_string(:normal)

  defp to_venue_type(%Tai.Trading.Order{side: :buy}), do: 1
  defp to_venue_type(%Tai.Trading.Order{side: :sell}), do: 2

  defp to_venue_order_type(%Tai.Trading.Order{post_only: true}), do: 1
  defp to_venue_order_type(_), do: 0

  defdelegate send_to_venue(params, config), to: ExOkex.Futures.Private, as: :create_order

  defp parse_response(
         {:ok, %{"result" => true, "order_info" => [%{"order_id" => venue_order_id} | _]}}
       ) do
    response = %CreateAccepted{id: venue_order_id, received_at: Timex.now()}
    {:ok, response}
  end

  # defp parse_response({:error, :timeout, nil}, _), do: {:error, :timeout}
  # defp parse_response({:error, :connect_timeout, nil}, _), do: {:error, :connect_timeout}
  # defp parse_response({:error, :rate_limited, _}, _), do: {:error, :rate_limited}

  # defp parse_response({:error, {:insufficient_balance, _}, _}, _),
  #   do: {:error, :insufficient_balance}

  # defp parse_response({:error, reason, _}, _), do: {:error, {:unhandled, reason}}
end
