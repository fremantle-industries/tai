defmodule Tai.ExchangeAdapters.Poloniex.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the Poloniex adapter
  """

  alias Tai.ExchangeAdapters.Poloniex.SymbolMapping

  def create(order, _credentials) do
    venue_time_in_force = to_venue_time_in_force(order.time_in_force)
    venue_product_symbol = SymbolMapping.to_poloniex(order.symbol)

    venue_product_symbol
    |> send(order.price, order.qty, venue_time_in_force, order.side)
    |> parse_response(order.qty, order.time_in_force)
  end

  defp send(venue_product_symbol, price, qty, venue_time_in_force, :buy) do
    ExPoloniex.Trading.buy(venue_product_symbol, price, qty, venue_time_in_force)
  end

  defp send(venue_product_symbol, price, qty, venue_time_in_force, :sell) do
    ExPoloniex.Trading.sell(venue_product_symbol, price, qty, venue_time_in_force)
  end

  defp parse_response(
         {:ok, %ExPoloniex.OrderResponse{} = poloniex_response},
         original_qty,
         time_in_force
       ) do
    response = %Tai.Trading.OrderResponse{
      id: poloniex_response.order_number,
      status: status(time_in_force),
      time_in_force: time_in_force,
      original_size: original_qty |> to_decimal,
      cumulative_qty: cumulative_qty(poloniex_response.resulting_trades)
    }

    {:ok, response}
  end

  defp parse_response({:error, %ExPoloniex.FillOrKillError{} = error}, _, _) do
    {:error, %Tai.Trading.FillOrKillError{reason: error}}
  end

  defp parse_response({:error, %HTTPoison.Error{reason: "timeout"}}, _, _) do
    {:error, :timeout}
  end

  defp parse_response({:error, %ExPoloniex.AuthenticationError{} = reason}, _, _) do
    {:error, {:credentials, reason}}
  end

  defp parse_response({:error, %ExPoloniex.NotEnoughError{} = error}, _, _) do
    {:error, %Tai.Trading.InsufficientBalanceError{reason: error}}
  end

  defp to_venue_time_in_force(:fok), do: %ExPoloniex.OrderDurations.FillOrKill{}
  defp to_venue_time_in_force(:ioc), do: %ExPoloniex.OrderDurations.ImmediateOrCancel{}

  defp status(:fok), do: :expired
  defp status(:ioc), do: :expired

  defp cumulative_qty(resulting_trades) do
    resulting_trades
    |> Enum.reduce(
      Decimal.new(0),
      fn %ExPoloniex.Trade{amount: amount}, acc ->
        amount
        |> to_decimal
        |> Decimal.add(acc)
      end
    )
  end

  defp to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  defp to_decimal(val), do: val |> Decimal.new()
end
