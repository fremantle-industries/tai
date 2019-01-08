defmodule Tai.ExchangeAdapters.Binance.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the Binance adapter
  """

  def create(%Tai.Trading.Order{} = order) do
    venue_time_in_force = to_venue_time_in_force(order.time_in_force)
    venue_product_symbol = Tai.ExchangeAdapters.Binance.SymbolMapping.to_binance(order.symbol)

    venue_product_symbol
    |> send(order.price, order.qty, venue_time_in_force, order.side)
    |> parse_response(order.time_in_force)
  end

  defp send(venue_product_symbol, price, size, venue_time_in_force, :sell) do
    Binance.order_limit_sell(venue_product_symbol, size, price, venue_time_in_force)
  end

  defp send(venue_product_symbol, price, size, venue_time_in_force, :buy) do
    Binance.order_limit_buy(venue_product_symbol, size, price, venue_time_in_force)
  end

  defp parse_response({:ok, %Binance.OrderResponse{} = binance_response}, time_in_force) do
    response = %Tai.Trading.OrderResponse{
      id: binance_response.order_id,
      status: binance_response.status |> from_venue_status,
      time_in_force: time_in_force,
      original_size: Decimal.new(binance_response.orig_qty),
      cumulative_qty: Decimal.new(binance_response.executed_qty)
    }

    {:ok, response}
  end

  defp parse_response({:error, %Binance.InsufficientBalanceError{} = reason}, _time_in_force) do
    {:error, %Tai.Trading.InsufficientBalanceError{reason: reason}}
  end

  defp parse_response({:error, _reason} = response, _time_in_force), do: response

  defp to_venue_time_in_force(:fok), do: "FOK"
  defp to_venue_time_in_force(:ioc), do: "IOC"

  defp from_venue_status("EXPIRED"), do: :expired
end
