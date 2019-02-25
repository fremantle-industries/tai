defmodule Tai.Trading.Orders.Cancel do
  alias Tai.Trading.{Orders, OrderStore}

  @type order :: Tai.Trading.Order.t()

  @spec cancel(order) ::
          {:ok, updated :: order}
          | {:error, {:invalid_status, was :: term, required :: term}}
  def cancel(%Tai.Trading.Order{client_id: client_id}) do
    with {:ok, {old, updated}} <- OrderStore.pend_cancel(client_id, Timex.now()) do
      Orders.updated!(old, updated)

      Task.start_link(fn ->
        try do
          updated
          |> send_cancel_order
          |> parse_cancel_order_response(updated)
        rescue
          e ->
            {e, __STACKTRACE__}
            |> rescue_venue_adapter_error(updated)
            |> notify_updated_order()
        end
      end)

      {:ok, updated}
    else
      {:error, {:invalid_status, was, required}} = error ->
        broadcast_invalid_status(client_id, :pend_cancel, was, required)
        error
    end
  end

  defdelegate send_cancel_order(order), to: Tai.Venue, as: :cancel_order

  defp notify_updated_order({:ok, {previous_order, order}}) do
    Orders.updated!(previous_order, order)
    order
  end

  defp parse_cancel_order_response({:ok, order_response}, order) do
    order.client_id
    |> OrderStore.cancel(order_response.venue_updated_at)
    |> case do
      {:ok, {_, _}} = result ->
        result |> notify_updated_order

      {:error, {:invalid_status, was, required}} ->
        broadcast_invalid_status(order.client_id, :cancel, was, required)
    end
  end

  defp parse_cancel_order_response({:error, reason}, order) do
    order.client_id
    |> OrderStore.cancel_error(reason, Timex.now())
    |> notify_updated_order()
  end

  defp rescue_venue_adapter_error(reason, order) do
    OrderStore.cancel_error(order.client_id, {:unhandled, reason}, Timex.now())
  end

  defp broadcast_invalid_status(client_id, action, was, required) do
    Tai.Events.broadcast(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      action: action,
      was: was,
      required: required
    })
  end
end
