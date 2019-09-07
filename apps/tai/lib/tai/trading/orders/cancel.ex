defmodule Tai.Trading.Orders.Cancel do
  alias Tai.Trading.{NotifyOrderUpdate, Order, OrderStore}
  alias Tai.Trading.OrderResponses.{Cancel, CancelAccepted}

  @type order :: Order.t()
  @type error_reason :: {:invalid_status, was :: term, required :: term}

  @spec cancel(order) :: {:ok, updated :: order} | {:error, error_reason}
  def cancel(%Order{client_id: client_id}) do
    with action <- %OrderStore.Actions.PendCancel{client_id: client_id},
         {:ok, {old, updated}} <- OrderStore.update(action) do
      NotifyOrderUpdate.notify!(old, updated)

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
      {:error, {:invalid_status, was, required, action}} = error ->
        warn_invalid_status(was, required, action)
        error
    end
  end

  defdelegate send_to_venue(order), to: Tai.Venue, as: :cancel_order

  defp parse_response({:ok, %Cancel{} = response}, order) do
    %OrderStore.Actions.Cancel{
      client_id: order.client_id,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_response({:ok, %CancelAccepted{} = response}, order) do
    %OrderStore.Actions.AcceptCancel{
      client_id: order.client_id,
      last_venue_timestamp: response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_response({:error, reason}, order) do
    %OrderStore.Actions.CancelError{
      client_id: order.client_id,
      reason: reason,
      last_received_at: Timex.now()
    }
    |> OrderStore.update()
  end

  defp rescue_venue_adapter_error(reason, order) do
    %OrderStore.Actions.CancelError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Timex.now()
    }
    |> OrderStore.update()
  end

  defp notify_updated_order({:ok, {previous_order, order}}) do
    NotifyOrderUpdate.notify!(previous_order, order)
  end

  defp notify_updated_order({:error, {:invalid_status, _, _, %action_name{}}})
       when action_name == OrderStore.Actions.AcceptCancel do
    :ok
  end

  defp warn_invalid_status(was, required, %action_name{} = action) do
    Tai.Events.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: action.client_id,
      action: action_name,
      last_received_at: action |> Map.get(:last_received_at),
      last_venue_timestamp: action |> Map.get(:last_venue_timestamp)
    })
  end
end
