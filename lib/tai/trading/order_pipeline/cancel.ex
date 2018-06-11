defmodule Tai.Trading.OrderPipeline.Cancel do
  require Logger

  def call(%Tai.Trading.Order{client_id: client_id}) do
    with {:ok, [old_order, updated_order]} <- find_pending_order_and_pre_cancel(client_id) do
      log_canceling(client_id)
      Tai.Trading.Order.updated_callback(old_order, updated_order)
      send_cancel_order!(updated_order)

      {:ok, updated_order}
    else
      {:error, :not_found} ->
        client_id
        |> Tai.Trading.OrderStore.find()
        |> case do
          order = %Tai.Trading.Order{} ->
            log_could_not_cancel(order)
            {:error, :order_status_must_be_pending}
        end
    end
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

  defp send_cancel_order!(order) do
    {:ok, _pid} =
      Task.start_link(fn ->
        order.account_id
        |> Tai.Exchanges.Account.cancel_order(order.server_id)
        |> parse_cancel_order_response(order)
      end)
  end

  defp parse_cancel_order_response({:ok, _order_id}, %Tai.Trading.Order{client_id: client_id}) do
    {:ok, [old_order, updated_order]} = find_canceling_order_and_cancel(client_id)
    log_canceled(updated_order.client_id)
    Tai.Trading.Order.updated_callback(old_order, updated_order)
  end

  defp log_canceling(client_id) do
    Logger.info("order canceling - client_id: #{client_id}")
  end

  defp log_canceled(client_id) do
    Logger.info("order canceled - client_id: #{client_id}")
  end

  defp log_could_not_cancel(%Tai.Trading.Order{client_id: client_id, status: status}) do
    "could not cancel order client_id: ~s, status must be '~s' but it was '~s'"
    |> :io_lib.format([client_id, Tai.Trading.OrderStatus.pending(), status])
    |> Logger.warn()
  end
end
