defmodule Tai.ExchangeAdapters.Bitstamp.Account.OrderStatus do
  def fetch(order_id) do
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
