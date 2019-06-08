defmodule Tai.VenueAdapters.Binance.CreateOrder do
  @moduledoc """
  Create orders for the Binance adapter
  """

  # @type credentials :: Tai.Venues.Adapter.credentials()
  # @type order :: Tai.Trading.Order.t()
  # @type response :: Tai.Trading.OrderResponses.Create.t()
  # @type reason ::
  #         :timeout
  #         | :connect_timeout
  #         | :overloaded
  #         | :insufficient_balance
  #         | {:nonce_not_increasing, msg :: String.t()}
  #         | {:unhandled, term}

  @limit "LIMIT"

  def create_order(%Tai.Trading.Order{side: side, type: :limit} = order, credentials) do
    venue_time_in_force = order.time_in_force |> to_venue_time_in_force
    venue_side = side |> Atom.to_string() |> String.upcase()
    credentials = struct!(ExBinance.Credentials, credentials)

    order.product_symbol
    |> to_venue_symbol
    |> ExBinance.Private.create_order(
      venue_side,
      @limit,
      order.qty,
      order.price,
      venue_time_in_force,
      credentials
    )
    |> parse_response(order)
  end

  defdelegate to_venue_symbol(product_symbol),
    to: Tai.VenueAdapters.Binance.SymbolMapping,
    as: :to_binance

  defp to_venue_time_in_force(:gtc), do: "GTC"
  defp to_venue_time_in_force(:fok), do: "FOK"
  defp to_venue_time_in_force(:ioc), do: "IOC"

  defp from_venue_status("EXPIRED"), do: :expired
  defp from_venue_status("NEW"), do: :open

  defp leaves_qty(:expired, _, _), do: Decimal.new(0)

  defp leaves_qty(:open, original_size, cumulative_qty),
    do: original_size |> Decimal.sub(cumulative_qty)

  defp parse_response({:ok, %ExBinance.Responses.CreateOrder{} = binance_response}, _) do
    received_at = Timex.now()

    # avg_price =
    #   (venue_order.avg_px && Tai.Utils.Decimal.from(venue_order.avg_px)) || Decimal.new(0)
    # TODO: Might need to include fills to calculate this
    avg_price = Decimal.new(0)
    status = binance_response.status |> from_venue_status()
    original_size = binance_response.orig_qty |> Decimal.new() |> Decimal.reduce()
    cumulative_qty = binance_response.executed_qty |> Decimal.new() |> Decimal.reduce()
    leaves_qty = leaves_qty(status, original_size, cumulative_qty)
    venue_timestamp = binance_response.transact_time |> DateTime.from_unix!(:millisecond)

    response = %Tai.Trading.OrderResponses.Create{
      id: binance_response.order_id,
      status: status,
      avg_price: avg_price,
      original_size: original_size,
      leaves_qty: leaves_qty,
      cumulative_qty: cumulative_qty,
      venue_timestamp: venue_timestamp,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout} = error, _), do: error
  defp parse_response({:error, :connect_timeout} = error, _), do: error

  # defp parse_response({:error, :rate_limited, _}, _), do: {:error, :rate_limited}

  defp parse_response({:error, {:insufficient_balance, _}}, _),
    do: {:error, :insufficient_balance}

  defp parse_response({:error, reason}, _), do: {:error, {:unhandled, reason}}
end
