defmodule Tai.Trading.Orders.Cancel do
  alias Tai.Trading.Orders

  @type order :: Tai.Trading.Order.t()

  @spec cancel(order) :: {:ok, updated_order :: order} | {:error, :order_status_must_be_open}
  def cancel(%Tai.Trading.Order{client_id: client_id}) do
    with {:ok, {old_order, updated_order}} <- find_open_order_and_pre_cancel(client_id) do
      Orders.updated!(old_order, updated_order)

      Task.start_link(fn ->
        updated_order
        |> send_cancel_order
        |> parse_cancel_order_response(updated_order)
      end)

      {:ok, updated_order}
    else
      {:error, :not_found} -> handle_invalid_status(client_id)
    end
  end

  defp send_cancel_order(order), do: Tai.Venue.cancel_order(order)

  defp parse_cancel_order_response({:ok, order_response}, order) do
    {:ok, {old_order, updated_order}} =
      find_pending_cancel_order_and_cancel(order.client_id, order_response)

    Orders.updated!(old_order, updated_order)
  end

  defp parse_cancel_order_response({:error, reason}, order) do
    {:ok, {old_order, updated_order}} =
      find_pending_cancel_order_and_error(order.client_id, reason)

    Orders.updated!(old_order, updated_order)
  end

  defp find_open_order_and_pre_cancel(client_id) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: :open],
      status: :pending_cancel,
      updated_at: Timex.now()
    )
  end

  defp find_pending_cancel_order_and_cancel(client_id, order_response) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id],
      status: :canceled,
      leaves_qty: order_response.leaves_qty,
      venue_updated_at: order_response.venue_updated_at
    )
  end

  defp find_pending_cancel_order_and_error(client_id, reason) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: :pending_cancel],
      status: :cancel_error,
      error_reason: reason
    )
  end

  defp handle_invalid_status(client_id) do
    {:ok, order} = Tai.Trading.OrderStore.find(client_id)

    Tai.Events.broadcast(%Tai.Events.CancelOrderInvalidStatus{
      client_id: client_id,
      was: order.status,
      required: :open
    })

    {:error, :order_status_must_be_open}
  end
end
