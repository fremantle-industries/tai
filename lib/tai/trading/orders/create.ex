defmodule Tai.Trading.Orders.Create do
  alias Tai.Trading.{OrderStore, OrderResponse, Order, Orders}

  @type order :: Order.t()
  @type submission :: OrderStore.submission()

  @spec create(submission) :: {:ok, order}
  def create(submission) do
    {:ok, order} = OrderStore.add(submission)

    order
    |> broadcast_updated_event()
    |> initial_update_callback()

    Task.async(fn ->
      if Tai.Settings.send_orders?() do
        order
        |> send
        |> parse_response(order)
        |> execute_callback()
      else
        order.client_id
        |> skip!
        |> execute_callback()
      end
    end)

    {:ok, order}
  end

  defp broadcast_updated_event(order) do
    Orders.broadcast(order)
    order
  end

  defp initial_update_callback(order) do
    execute_callback({nil, order})
  end

  defp execute_callback({previous_order, order}) do
    Orders.execute_update_callback(previous_order, order)
    order
  end

  defp send(order), do: Tai.Exchanges.Account.create_order(order)

  defp parse_response({:ok, %OrderResponse{status: :filled} = r}, %Order{} = o) do
    fill!(o.client_id, r.executed_size)
  end

  defp parse_response({:ok, %OrderResponse{status: :expired}}, %Order{client_id: cid}) do
    expire!(cid)
  end

  defp parse_response(
         {:ok, %OrderResponse{status: :open, id: venue_order_id}},
         %Order{client_id: cid}
       ) do
    open!(cid, venue_order_id)
  end

  defp parse_response({:error, reason}, %Order{client_id: cid}) do
    error!(cid, reason)
  end

  defp fill!(cid, executed_size) do
    cid
    |> find_by_and_update(
      status: :filled,
      executed_size: Decimal.new(executed_size)
    )
  end

  defp expire!(cid) do
    cid
    |> find_by_and_update(status: :expired)
  end

  defp open!(cid, venue_order_id) do
    cid
    |> find_by_and_update(
      status: :open,
      venue_order_id: venue_order_id
    )
  end

  defp error!(cid, reason) do
    cid
    |> find_by_and_update(
      status: :error,
      error_reason: reason
    )
  end

  defp skip!(cid) do
    cid
    |> find_by_and_update(status: :skip)
  end

  defp find_by_and_update(client_id, attrs) do
    {:ok, {old_order, updated_order}} =
      OrderStore.find_by_and_update(
        [client_id: client_id],
        attrs
      )

    Orders.Events.info(updated_order)

    {old_order, updated_order}
  end
end
