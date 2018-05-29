defmodule Tai.ExchangeAdapters.Binance.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the Binance adapter
  """

  def buy_limit(symbol, price, size, time_in_force) do
    with normalized_tif <- normalize_duration(time_in_force) do
      symbol
      |> Tai.Markets.Symbol.upcase()
      |> Binance.order_limit_buy(size, price, normalized_tif)
      |> parse_create_order(time_in_force)
    end
  end

  def sell_limit(symbol, price, size, time_in_force) do
    with normalized_tif <- normalize_duration(time_in_force) do
      symbol
      |> Tai.Markets.Symbol.upcase()
      |> Binance.order_limit_sell(size, price, normalized_tif)
      |> parse_create_order(time_in_force)
    end
  end

  defp parse_create_order({:ok, %Binance.OrderResponse{} = binance_response}, time_in_force) do
    response = %Tai.Trading.OrderResponse{
      id: binance_response.order_id,
      status: status(binance_response.status),
      time_in_force: time_in_force,
      original_size: Decimal.new(binance_response.orig_qty),
      executed_size: Decimal.new(binance_response.executed_qty)
    }

    {:ok, response}
  end

  defp normalize_duration(:fok), do: "FOK"
  defp normalize_duration(:ioc), do: "IOC"

  defp status("EXPIRED"), do: Tai.Trading.OrderStatus.expired()
end
