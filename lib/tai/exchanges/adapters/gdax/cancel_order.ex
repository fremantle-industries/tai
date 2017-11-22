defmodule Tai.Exchanges.Adapters.Gdax.CancelOrder do
  def cancel_order(order_id) do
    order_id
    |> ExGdax.cancel_order
    |> case do
      {:ok, _} ->
        {:ok, order_id}
    end
  end
end
