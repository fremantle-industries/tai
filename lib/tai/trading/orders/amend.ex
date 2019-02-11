defmodule Tai.Trading.Orders.Amend do
  alias Tai.Trading.{Orders, OrderStore}

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
    with {:ok, {old_order, updated_order}} <- OrderStore.pend_amend(order.client_id, Timex.now()) do
      Orders.updated!(old_order, updated_order)

      Task.start_link(fn ->
        try do
          updated_order
          |> send_amend_order(attrs)
          |> parse_response(updated_order.client_id)
          |> notify_updated_order()
        rescue
          e ->
            {e, __STACKTRACE__}
            |> rescue_venue_adapter_error(order)
            |> notify_updated_order()
        end
      end)

      {:ok, updated_order}
    else
      {:error, {:invalid_status, was, required}} = error ->
        broadcast_invalid_status(order.client_id, :pend_amend, was, required)
        error
    end
  end

  defdelegate send_amend_order(order, attrs), to: Tai.Venue, as: :amend_order

  defp notify_updated_order({:ok, {old, updated}}) do
    Orders.updated!(old, updated)
    updated
  end

  defp parse_response({:ok, amend_response}, client_id) do
    OrderStore.amend(
      client_id,
      amend_response.venue_updated_at,
      amend_response.price,
      amend_response.leaves_qty
    )
  end

  defp parse_response({:error, reason}, client_id) do
    OrderStore.amend_error(client_id, reason)
  end

  defp rescue_venue_adapter_error(reason, order) do
    OrderStore.amend_error(order.client_id, {:unhandled, reason})
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
