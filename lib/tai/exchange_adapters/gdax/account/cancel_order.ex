defmodule Tai.ExchangeAdapters.Gdax.Account.CancelOrder do
  def execute(order_id, %Tai.Exchanges.Account{} = account) do
    order_id
    |> ExGdax.cancel_order(account.credentials)
    |> handle_cancel_order(order_id)
  end

  defp handle_cancel_order({:ok, _}, order_id) do
    {:ok, order_id}
  end

  defp handle_cancel_order({:error, message, _status_code}, _order_id) do
    {:error, message}
  end
end
