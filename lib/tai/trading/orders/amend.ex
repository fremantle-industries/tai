defmodule Tai.Trading.Orders.Amend do
  alias Tai.Trading.Orders

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
    with {:ok, {old_order, updated_order}} <-
           Tai.Trading.OrderStore.pend_amend(order.client_id, Timex.now()) do
      Orders.updated!(old_order, updated_order)

      Task.start_link(fn ->
        updated_order
        |> send_amend_order(attrs)
        |> parse_response(updated_order.client_id)
      end)

      {:ok, updated_order}
    else
      {:error, {:invalid_status, was, required}} = error ->
        broadcast_invalid_status(order.client_id, :pend_amend, was, required)
        error
    end
  end

  defp send_amend_order(order, attrs), do: Tai.Venue.amend_order(order, attrs)

  defp parse_response({:ok, amend_response}, client_id) do
    {:ok, {old_order, updated_order}} =
      Tai.Trading.OrderStore.amend(
        client_id,
        amend_response.venue_updated_at,
        amend_response.price,
        amend_response.leaves_qty
      )

    Orders.updated!(old_order, updated_order)
  end

  defp parse_response({:error, reason}, client_id) do
    {:ok, {old_order, updated_order}} = Tai.Trading.OrderStore.amend_error(client_id, reason)
    Orders.updated!(old_order, updated_order)
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
