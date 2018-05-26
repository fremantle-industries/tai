defmodule Tai.ExchangeAdapters.Poloniex.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the Poloniex adapter
  """

  alias Tai.ExchangeAdapters.Poloniex.{SymbolMapping}

  def buy_limit(symbol, price, size, time_in_force) do
    with normalized_tif <- normalize_duration(time_in_force) do
      symbol
      |> SymbolMapping.to_poloniex()
      |> ExPoloniex.Trading.buy(price, size, normalized_tif)
      |> parse_create_order(size, time_in_force)
    end
  end

  defp parse_create_order(
         {:ok, %ExPoloniex.OrderResponse{} = poloniex_response},
         original_size,
         time_in_force
       ) do
    response = %Tai.Trading.OrderResponse{
      id: poloniex_response.order_number,
      status: status(time_in_force),
      time_in_force: time_in_force,
      original_size: Decimal.new(original_size),
      executed_size: executed_size(poloniex_response.resulting_trades)
    }

    {:ok, response}
  end

  defp parse_create_order({:error, %ExPoloniex.FillOrKillError{} = error}, _, _) do
    {:error, %Tai.Trading.FillOrKillError{reason: error}}
  end

  defp parse_create_order({:error, %HTTPoison.Error{reason: "timeout"} = error}, _, _) do
    {:error, %Tai.TimeoutError{reason: error}}
  end

  defp parse_create_order({:error, %ExPoloniex.AuthenticationError{} = error}, _, _) do
    {:error, %Tai.CredentialError{reason: error}}
  end

  defp parse_create_order({:error, %ExPoloniex.NotEnoughError{} = error}, _, _) do
    {:error, %Tai.Trading.NotEnoughError{reason: error}}
  end

  defp normalize_duration(%Tai.Trading.OrderDurations.FillOrKill{}),
    do: %ExPoloniex.OrderDurations.FillOrKill{}

  defp normalize_duration(%Tai.Trading.OrderDurations.ImmediateOrCancel{}),
    do: %ExPoloniex.OrderDurations.ImmediateOrCancel{}

  defp status(%Tai.Trading.OrderDurations.FillOrKill{}), do: Tai.Trading.OrderStatus.expired()

  defp status(%Tai.Trading.OrderDurations.ImmediateOrCancel{}),
    do: Tai.Trading.OrderStatus.expired()

  defp executed_size(resulting_trades) do
    resulting_trades
    |> Enum.reduce(
      Decimal.new(0.0),
      fn %ExPoloniex.Trade{amount: amount}, acc ->
        amount
        |> Decimal.new()
        |> Decimal.add(acc)
      end
    )
  end
end
