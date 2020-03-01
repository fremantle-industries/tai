defmodule Tai.Trading.Orders.Amend do
  alias Tai.Trading.{NotifyOrderUpdate, OrderStore}

  defmodule Provider do
    defdelegate update(action), to: OrderStore
  end

  @type order :: Tai.Trading.Order.t()
  @type status :: Tai.Trading.Order.status()
  @type status_required :: status | [status]
  @type attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }
  @type action :: Tai.Trading.OrderStore.Action.t()
  @type response ::
          {:ok, updated :: order}
          | {:error, {:invalid_status, was :: status, status_required, action}}

  @spec amend(order, attrs) :: response
  def amend(order, attrs, provider \\ Provider) when is_map(attrs) do
    with action <- %OrderStore.Actions.PendAmend{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(action) do
      NotifyOrderUpdate.notify!(old, updated)

      Task.async(fn ->
        try do
          updated
          |> send_amend_order(attrs)
          |> parse_response(updated.client_id, provider)
          |> notify_updated_order()
        rescue
          e ->
            {e, __STACKTRACE__}
            |> rescue_venue_adapter_error(updated, provider)
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

  defdelegate send_amend_order(order, attrs), to: Tai.Venues.Client, as: :amend_order

  defp parse_response({:ok, amend_response}, client_id, provider) do
    %OrderStore.Actions.Amend{
      client_id: client_id,
      price: amend_response.price,
      leaves_qty: amend_response.leaves_qty,
      last_received_at: Timex.now(),
      last_venue_timestamp: amend_response.venue_timestamp
    }
    |> provider.update()
  end

  defp parse_response({:error, reason}, client_id, provider) do
    %OrderStore.Actions.AmendError{
      client_id: client_id,
      reason: reason,
      last_received_at: Timex.now()
    }
    |> provider.update()
  end

  defp rescue_venue_adapter_error(reason, order, provider) do
    %OrderStore.Actions.AmendError{
      client_id: order.client_id,
      reason: {:unhandled, reason},
      last_received_at: Timex.now()
    }
    |> provider.update()
  end

  defp notify_updated_order({:ok, {old, updated}}) do
    NotifyOrderUpdate.notify!(old, updated)
    updated
  end

  defp notify_updated_order({:error, {:invalid_status, was, required, action}}) do
    warn_invalid_status(was, required, action)
  end

  defp warn_invalid_status(was, required, %action_name{} = action) do
    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: action.client_id,
      action: action_name,
      last_received_at: action |> Map.get(:last_received_at),
      last_venue_timestamp: action |> Map.get(:last_venue_timestamp),
      was: was,
      required: required
    })
  end
end
