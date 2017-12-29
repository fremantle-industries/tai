defmodule Tai.Exchanges.Adapters.Bitstamp.Orders do
  alias Tai.OrderResponse

  def buy_limit(symbol, price, size) do
    ExBitstamp.buy_limit(symbol, price, size)
    |> handle_create_order
  end

  def sell_limit(symbol, price, size) do
    ExBitstamp.sell_limit(symbol, price, size)
    |> handle_create_order
  end

  defp handle_create_order({:ok, %{"id" => id}}) do
    {:ok, %OrderResponse{id: id, status: :pending}}
  end
  defp handle_create_order({:error, details}) do
    {:error, details}
  end
end
