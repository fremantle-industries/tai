defmodule Tai.Trading.Orders.Amend do
  alias Tai.Trading.Orders

  @type order :: Tai.Trading.Order.t()
  @type attrs :: %{
          optional(:price) => Decimal.t(),
          optional(:size) => Decimal.t()
        }

  @spec amend(order, attrs) :: {:ok, order} | {:error, :order_status_must_be_open}
  def amend(order, attrs) when is_map(attrs) do
    with {:ok, {old_order, updated_order}} <- find_open_order_and_pend_amend(order.client_id) do
      Orders.updated!(old_order, updated_order)

      Task.start_link(fn ->
        updated_order
        |> send_amend_order(attrs)
        |> parse_response(updated_order.client_id, attrs)
      end)

      {:ok, updated_order}
    else
      {:error, :not_found} -> handle_invalid_status(order.client_id)
    end
  end

  # defp send_amend_order(order, attrs), do: Tai.Venue.amend_order(order, attrs)
  defp send_amend_order(order, attrs), do: Tai.Exchanges.Account.amend_order(order, attrs)

  defp parse_response({:ok, _order_response}, client_id, attrs) do
    {:ok, {old_order, updated_order}} = find_pending_amend_order_and_open(client_id, attrs)
    Orders.updated!(old_order, updated_order)
  end

  defp find_open_order_and_pend_amend(client_id) do
    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: :open],
      status: :pending_amend
    )
  end

  defp find_pending_amend_order_and_open(client_id, attrs) do
    update_attrs =
      attrs
      |> Map.to_list()
      |> Keyword.put(:status, :open)

    Tai.Trading.OrderStore.find_by_and_update(
      [client_id: client_id, status: :pending_amend],
      update_attrs
    )
  end

  defp handle_invalid_status(client_id) do
    {:ok, order} = Tai.Trading.OrderStore.find(client_id)

    Tai.Events.broadcast(%Tai.Events.OrderErrorAmendHasInvalidStatus{
      client_id: client_id,
      was: order.status,
      required: :open
    })

    {:error, :order_status_must_be_open}
  end
end
