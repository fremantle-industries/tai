defmodule Tai.ExchangeAdapters.Gdax.Account.OrderStatus do
  def fetch(order_id) do
    order_id
    |> ExGdax.get_order()
    |> handle_order_status
  end

  defp handle_order_status({:ok, %{"status" => status}}) do
    {:ok, status |> to_atom}
  end

  defp handle_order_status({:error, message, _status_code}) do
    {:error, message}
  end

  def to_atom("pending"), do: :pending
  def to_atom("open"), do: :open
end
