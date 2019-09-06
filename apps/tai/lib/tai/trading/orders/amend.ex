defmodule Tai.Trading.Orders.Amend do
  alias Tai.Trading.{NotifyOrderUpdate, OrderStore}

  @type order :: Tai.Trading.Order.t()
  @type status :: Tai.Trading.Order.status()
  @type status_was :: status
  @type status_required :: status | [status]
  @type attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }

  @spec amend(order, attrs) ::
          {:ok, updated :: order}
          | {:error, {:invalid_status, status_was, status_required}}
  def amend(order, attrs) when is_map(attrs) do
    with action <- %OrderStore.Actions.PendAmend{client_id: order.client_id},
         {:ok, {old, updated}} <- OrderStore.update(action) do
      NotifyOrderUpdate.notify!(old, updated)

      Task.async(fn ->
        try do
          updated
          |> send_amend_order(attrs)
          |> parse_response(updated.client_id)
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
        broadcast_invalid_status(order.client_id, :pend_amend, was, required)
        error
    end
  end

  defdelegate send_amend_order(order, attrs), to: Tai.Venue, as: :amend_order

  defp notify_updated_order({:ok, {old, updated}}) do
    NotifyOrderUpdate.notify!(old, updated)
    updated
  end

  defp parse_response({:ok, amend_response}, client_id) do
    %OrderStore.Actions.Amend{
      client_id: client_id,
      price: amend_response.price,
      leaves_qty: amend_response.leaves_qty,
      last_received_at: Timex.now(),
      last_venue_timestamp: amend_response.venue_timestamp
    }
    |> OrderStore.update()
  end

  defp parse_response({:error, reason}, client_id) do
    %OrderStore.Actions.AmendError{
      client_id: client_id,
      reason: reason,
      last_received_at: Timex.now()
    }
    |> OrderStore.update()
  end

  defp rescue_venue_adapter_error(reason, order) do
    %OrderStore.Actions.AmendError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Timex.now()
    }
    |> OrderStore.update()
  end

  defp broadcast_invalid_status(client_id, action, was, required) do
    Tai.Events.info(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      action: action,
      was: was,
      required: required
    })
  end
end
