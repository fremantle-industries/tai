defmodule Tai.ExchangeAdapters.Bitstamp.CancelOrder do
  def cancel_order(order_id) do
    order_id
    |> ExBitstamp.cancel_order
    |> handle_cancel_order
  end

  defp handle_cancel_order({:ok, %{"id" => order_id}}) do
    {:ok, order_id}
  end
  defp handle_cancel_order({:error, reason}) do
    {:error, reason}
  end
end
