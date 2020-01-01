defmodule Tai.Trading.Orders.AmendBulk do
  alias Tai.Trading.{NotifyOrderUpdate, OrderStore}
  alias Tai.Events

  defmodule Provider do
    defdelegate update(action), to: OrderStore
  end

  @type action :: Tai.Trading.OrderStore.Action.t()
  @type order :: Tai.Trading.Order.t()
  @type status :: Tai.Trading.Order.status()
  @type status_required :: status | [status]
  @type attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }
  @type orders_and_attributes :: [{order, attrs}]
  @type reject_reason :: {:invalid_status, was :: status, status_required, action}
  @type response :: [{:ok, updated :: order} | {:error, reject_reason}]

  @spec amend_bulk(orders_and_attributes) :: response
  def amend_bulk(orders_and_attributes, provider \\ Provider)
      when is_list(orders_and_attributes) do
    pending_orders = orders_and_attributes |> Enum.map(&mark_order_pending(&1, provider))

    Task.async(fn ->
      try do
        pending_orders
        |> Enum.reduce([], fn
          {:ok, pending_order}, acc ->
            {_, order_attributes} =
              Enum.find(orders_and_attributes, fn {order, _} ->
                order.client_id == pending_order.client_id
              end)

            [{pending_order, order_attributes} | acc]

          {:error, _}, acc ->
            acc
        end)
        |> send_amend_orders()
        |> parse_response(orders_and_attributes, provider)
        |> Enum.map(&notify_updated_order/1)
      rescue
        e ->
          {e, __STACKTRACE__}
          |> rescue_venue_adapter_error(orders_and_attributes, provider)
          |> Enum.map(&notify_updated_order/1)
      end
    end)

    pending_orders
  end

  defdelegate send_amend_orders(orders), to: Tai.Venues.Client, as: :amend_bulk_orders

  defp parse_response({:ok, %{orders: amend_responses}}, orders_and_attributes, provider) do
    amend_responses
    |> Enum.map(fn amend_response ->
      order =
        Enum.find(orders_and_attributes, fn {order, _} ->
          order.venue_order_id == amend_response.id
        end)
        |> elem(0)

      %OrderStore.Actions.Amend{
        client_id: order.client_id,
        price: amend_response.price,
        leaves_qty: amend_response.leaves_qty,
        last_received_at: Timex.now(),
        last_venue_timestamp: amend_response.venue_timestamp
      }
      |> provider.update()
    end)
  end

  defp parse_response({:error, reason}, orders_and_attributes, provider) do
    orders_and_attributes
    |> Enum.map(fn {order, _} ->
      %OrderStore.Actions.AmendError{
        client_id: order.client_id,
        reason: reason,
        last_received_at: Timex.now()
      }
      |> provider.update()
    end)
  end

  defp rescue_venue_adapter_error(reason, orders_and_attributes, provider) do
    orders_and_attributes
    |> Enum.map(fn {order, _} ->
      %OrderStore.Actions.AmendError{
        client_id: order.client_id,
        reason: reason,
        last_received_at: Timex.now()
      }
      |> provider.update()
    end)
  end

  defp warn_invalid_status(was, required, %action_name{} = action) do
    Events.warn(%Events.OrderUpdateInvalidStatus{
      client_id: action.client_id,
      action: action_name,
      last_received_at: action |> Map.get(:last_received_at),
      last_venue_timestamp: action |> Map.get(:last_venue_timestamp),
      was: was,
      required: required
    })
  end

  defp notify_updated_order({:ok, {old, updated}}) do
    NotifyOrderUpdate.notify!(old, updated)
    updated
  end

  defp mark_order_pending({order, _}, provider) do
    with action <- %OrderStore.Actions.PendAmend{client_id: order.client_id},
         {:ok, {old, updated}} <- provider.update(action) do
      NotifyOrderUpdate.notify!(old, updated)
      {:ok, updated}
    else
      {:error, {:invalid_status, was, required, action}} = error ->
        warn_invalid_status(was, required, action)
        error
    end
  end
end
