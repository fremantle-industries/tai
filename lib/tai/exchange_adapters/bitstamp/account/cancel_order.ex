defmodule Tai.ExchangeAdapters.Bitstamp.Account.CancelOrder do
  def execute(order_id) do
    order_id
    |> ExBitstamp.cancel_order
    |> handle_cancel_order
  end

  defp handle_cancel_order({:ok, %{"id" => order_id}}) do
    {:ok, order_id |> Integer.to_string}
  end
  defp handle_cancel_order({:error, reason}) do
    {:error, reason}
  end
end
