defmodule Tai.Exchanges.Adapters.Bitstamp.OrderStatus do
  def order_status(order_id) do
    order_id
    |> ExBitstamp.order_status
    |> case do
      {:ok, %{"status" => status}} ->
        {:ok, status |> String.downcase |> String.to_atom}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
