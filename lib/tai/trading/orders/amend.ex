defmodule Tai.Trading.Orders.Amend do
  alias Tai.Trading.Orders

  @type order :: Tai.Trading.Order.t()
  @type attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:qty) => Decimal.t()
        }

  @amendable_status [:open, :amend_error]

  @spec amend(order, attrs) ::
          {:ok, updated_order :: order} | {:error, {:invalid_order_status, String.t()}}
  def amend(order, attrs) when is_map(attrs) do
    with {:ok, {old_order, updated_order}} <- find_amendable_order_and_pend_amend(order.client_id) do
      Orders.updated!(old_order, updated_order)

      Task.start_link(fn ->
        updated_order
        |> send_amend_order(attrs)
        |> parse_response(updated_order.client_id)
      end)

      {:ok, updated_order}
    else
      {:error, :not_found} -> handle_invalid_status(order.client_id)
    end
  end

  defp send_amend_order(order, attrs), do: Tai.Venue.amend_order(order, attrs)

  defp parse_response({:ok, amend_response}, client_id) do
    {:ok, {old_order, updated_order}} =
      find_pending_amend_order_and_open(client_id, amend_response)

    Orders.updated!(old_order, updated_order)
  end

  defp parse_response({:error, reason}, client_id) do
    {:ok, {old_order, updated_order}} = find_pending_amend_order_and_error(client_id, reason)
    Orders.updated!(old_order, updated_order)
  end

  defp find_amendable_order_and_pend_amend(client_id) do
    client_id |> find_amendable_order_and_pend_amend(@amendable_status)
  end

  defp find_amendable_order_and_pend_amend(_, []), do: {:error, :not_found}

  defp find_amendable_order_and_pend_amend(client_id, [status_to_check | unchecked_status]) do
    [client_id: client_id, status: status_to_check]
    |> Tai.Trading.OrderStore.find_by_and_update(status: :pending_amend, updated_at: Timex.now())
    |> case do
      {:ok, _} = result -> result
      {:error, :not_found} -> find_amendable_order_and_pend_amend(client_id, unchecked_status)
    end
  end

  defp find_pending_amend_order_and_open(client_id, amend_response) do
    update_attrs = [
      status: :open,
      price: amend_response.price,
      leaves_qty: amend_response.leaves_qty,
      venue_updated_at: amend_response.venue_updated_at
    ]

    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: :pending_amend],
      update_attrs
    )
  end

  defp find_pending_amend_order_and_error(client_id, reason) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: :pending_amend],
      status: :amend_error,
      error_reason: reason
    )
  end

  defp handle_invalid_status(client_id) do
    {:ok, order} = Tai.Trading.OrderStore.find(client_id)
    required = stringify_amendable_status()

    Tai.Events.broadcast(%Tai.Events.OrderErrorAmendHasInvalidStatus{
      client_id: client_id,
      was: order.status,
      required: required
    })

    reason = {:invalid_order_status, "Must be #{required}, but it was #{order.status}"}
    {:error, reason}
  end

  defp stringify_amendable_status, do: Enum.join(@amendable_status, " | ")
end
