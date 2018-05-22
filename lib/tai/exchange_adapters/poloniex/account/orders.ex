defmodule Tai.ExchangeAdapters.Poloniex.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the Poloniex adapter
  """

  alias Tai.ExchangeAdapters.Poloniex.{SymbolMapping}

  def buy_limit(symbol, price, size, duration) do
    poloniex_duration = normalize_duration(duration)

    symbol
    |> SymbolMapping.to_poloniex()
    |> ExPoloniex.Trading.buy(price, size, poloniex_duration)
    |> handle_create_order
  end

  defp handle_create_order({:ok, %ExPoloniex.OrderResponse{} = response}) do
    {:ok, %Tai.Trading.OrderResponse{id: response.order_number}}
  end

  defp handle_create_order({:error, %ExPoloniex.FillOrKillError{} = error}) do
    {:error, %Tai.Trading.FillOrKillError{reason: error}}
  end

  defp handle_create_order({:error, %HTTPoison.Error{reason: "timeout"} = error}) do
    {:error, %Tai.TimeoutError{reason: error}}
  end

  defp handle_create_order({:error, %ExPoloniex.AuthenticationError{} = error}) do
    {:error, %Tai.CredentialError{reason: error}}
  end

  defp handle_create_order({:error, %ExPoloniex.NotEnoughError{} = error}) do
    {:error, %Tai.Trading.NotEnoughError{reason: error}}
  end

  defp normalize_duration(%Tai.Trading.OrderDurations.FillOrKill{}),
    do: %ExPoloniex.OrderDurations.FillOrKill{}

  defp normalize_duration(%Tai.Trading.OrderDurations.ImmediateOrCancel{}),
    do: %ExPoloniex.OrderDurations.ImmediateOrCancel{}
end
