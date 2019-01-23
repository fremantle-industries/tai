defmodule Tai.Trading.Orders.Cancel do
  alias Tai.Trading.{Orders, OrderStore}

  @type order :: Tai.Trading.Order.t()

  @spec cancel(order) ::
          {:ok, updated :: order}
          | {:error, {:invalid_status, was :: term, required :: term}}
  def cancel(%Tai.Trading.Order{client_id: client_id}) do
    with {:ok, {old_order, updated_order}} <-
           OrderStore.pend_cancel(client_id, Timex.now()) do
      Orders.updated!(old_order, updated_order)

      Task.start_link(fn ->
        updated_order
        |> send_cancel_order
        |> parse_cancel_order_response(updated_order)
      end)

      {:ok, updated_order}
    else
      {:error, {:invalid_status, was, required}} = error ->
        broadcast_invalid_status(client_id, was, required)
        error
    end
  end

  defp send_cancel_order(order), do: Tai.Venue.cancel_order(order)

  defp parse_cancel_order_response({:ok, order_response}, order) do
    {:ok, {old_order, updated_order}} =
      OrderStore.cancel(order.client_id, order_response.venue_updated_at)

    Orders.updated!(old_order, updated_order)
  end

  defp parse_cancel_order_response({:error, reason}, order) do
    {:ok, {old_order, updated_order}} = OrderStore.cancel_error(order.client_id, reason)

    Orders.updated!(old_order, updated_order)
  end

  defp broadcast_invalid_status(client_id, was, required) do
    Tai.Events.broadcast(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      was: was,
      required: required
    })
  end
end
