defmodule Tai.Trading.OrderPipeline.Cancel do
  require Logger

  def execute_step(%Tai.Trading.Order{client_id: client_id}) do
    with {:ok, [old_order, updated_order]} <- find_pending_order_and_pre_cancel(client_id) do
      Tai.Trading.OrderPipeline.Logger.info(updated_order)
      Tai.Trading.Order.execute_update_callback(old_order, updated_order)

      Task.start_link(fn ->
        updated_order
        |> send_cancel_order
        |> parse_cancel_order_response(updated_order)
      end)

      {:ok, updated_order}
    else
      {:error, :not_found} ->
        client_id
        |> Tai.Trading.OrderStore.find()
        |> case do
          {:ok, order = %Tai.Trading.Order{}} ->
            log_could_not_cancel(order)
            {:error, :order_status_must_be_pending}
        end
    end
  end

  defp send_cancel_order(order) do
    Tai.Exchanges.Account.cancel_order(order.exchange_id, order.account_id, order.server_id)
  end

  defp parse_cancel_order_response({:ok, _order_id}, order) do
    {:ok, [old_order, updated_order]} = find_canceling_order_and_cancel(order.client_id)
    Tai.Trading.OrderPipeline.Logger.info(updated_order)
    Tai.Trading.Order.execute_update_callback(old_order, updated_order)
  end

  defp parse_cancel_order_response({:error, :not_found = reason}, order) do
    {:ok, [old_order, updated_order]} = find_canceling_order_and_error(order.client_id, reason)
    Tai.Trading.OrderPipeline.Logger.info(updated_order)
    Tai.Trading.Order.execute_update_callback(old_order, updated_order)
  end

  defp find_pending_order_and_pre_cancel(client_id) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: Tai.Trading.OrderStatus.pending()],
      status: Tai.Trading.OrderStatus.canceling()
    )
  end

  defp find_canceling_order_and_cancel(client_id) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id],
      status: Tai.Trading.OrderStatus.canceled()
    )
  end

  defp find_canceling_order_and_error(client_id, reason) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: Tai.Trading.OrderStatus.canceling()],
      status: Tai.Trading.OrderStatus.error(),
      error_reason: reason
    )
  end

  defp log_could_not_cancel(%Tai.Trading.Order{client_id: client_id, status: status}) do
    "could not cancel order client_id: ~s, status must be '~s' but it was '~s'"
    |> :io_lib.format([client_id, Tai.Trading.OrderStatus.pending(), status])
    |> Logger.warn()
  end
end
