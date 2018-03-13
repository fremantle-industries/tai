defmodule Tai.ExchangeAdapters.Bitstamp.Account.Orders do
  alias Tai.Trading.OrderResponses

  def buy_limit(symbol, price, size) do
    ExBitstamp.buy_limit(symbol, price, size)
    |> handle_create_order
  end

  def sell_limit(symbol, price, size) do
    ExBitstamp.sell_limit(symbol, price, size)
    |> handle_create_order
  end

  defp handle_create_order({:ok, %{"id" => id, "datetime" => datetime}}) do
    created_at = Timex.parse!(datetime, "{ISO:Extended}") |> Timex.to_datetime
    order_response = %OrderResponses.Created{id: id, status: :pending, created_at: created_at}

    {:ok, order_response}
  end
  defp handle_create_order({:error, details}) do
    {:error, details}
  end
end
