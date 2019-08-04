defmodule Tai.Trading.Orders.Cancel do
  alias Tai.Trading.{Order, Orders, OrderStore}
  alias Tai.Trading.OrderResponses.{Cancel, CancelAccepted}

  @type order :: Order.t()
  @type error_reason :: {:invalid_status, was :: term, required :: term}

  @spec cancel(order) :: {:ok, updated :: order} | {:error, error_reason}
  def cancel(%Order{client_id: client_id}) do
    with action <- %OrderStore.Actions.PendCancel{client_id: client_id},
         {:ok, {old, updated}} <- OrderStore.update(action) do
      Orders.updated!(old, updated)

      Task.async(fn ->
        try do
          updated
          |> send_to_venue()
          |> parse_response(updated)
          |> notify_updated_order()
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

  defdelegate send_to_venue(order), to: Tai.Venue, as: :cancel_order

  defp parse_response({:ok, %Cancel{} = response}, order) do
    result =
      %OrderStore.Actions.Cancel{
        client_id: order.client_id,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:cancel, result}
  end

  defp parse_response({:ok, %CancelAccepted{} = response}, order) do
    result =
      %OrderStore.Actions.AcceptCancel{
        client_id: order.client_id,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:accept_cancel, result}
  end

  defp parse_response({:error, reason}, order) do
    result =
      %OrderStore.Actions.CancelError{
        client_id: order.client_id,
        reason: reason,
        last_received_at: Timex.now()
      }
      |> OrderStore.update()

    {:cancel_error, result}
  end

  defp rescue_venue_adapter_error(reason, order) do
    result =
      %OrderStore.Actions.CancelError{
        client_id: order.client_id,
        reason: {:unhandled, reason},
        last_received_at: Timex.now()
      }
      |> OrderStore.update()

    {:cancel_error, result}
  end

  defp notify_updated_order({_, {:ok, {previous_order, order}}}),
    do: Orders.updated!(previous_order, order)

  defp notify_updated_order({:accept_cancel, {:error, {:invalid_status, _, _}}}), do: :ok

  defp broadcast_invalid_status(client_id, action, was, required) do
    Tai.Events.error(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      action: action,
      was: was,
      required: required
    })
  end
end
