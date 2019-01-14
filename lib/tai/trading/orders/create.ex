defmodule Tai.Trading.Orders.Create do
  alias Tai.Trading.{OrderStore, OrderResponses, Order, Orders}

  @type order :: Order.t()
  @type submission :: OrderStore.submission()

  @spec create(submission) :: {:ok, order}
  def create(submission) do
    {:ok, order} = OrderStore.add(submission)
    notify_initial_updated_order(order)

    Task.async(fn ->
      if Tai.Settings.send_orders?() do
        order
        |> send
        |> parse_response(order)
        |> notify_updated_order()
      else
        order.client_id
        |> skip!
        |> notify_updated_order()
      end
    end)

    {:ok, order}
  end

  defp notify_initial_updated_order(order) do
    notify_updated_order({nil, order})
  end

  defp notify_updated_order({previous_order, order}) do
    Orders.updated!(previous_order, order)
    order
  end

  defp send(order), do: Tai.Venue.create_order(order)

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :filled} = response},
         %Order{} = o
       ) do
    fill!(o.client_id, response)
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :expired} = response},
         %Order{client_id: cid}
       ) do
    expire!(cid, response)
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :open} = response},
         %Order{client_id: cid}
       ) do
    open!(cid, response)
  end

  defp parse_response({:error, reason}, %Order{client_id: cid}) do
    error!(cid, reason)
  end

  defp fill!(cid, response) do
    cid
    |> find_by_and_update(
      status: :filled,
      venue_order_id: response.id,
      avg_price: response.avg_price,
      cumulative_qty: Decimal.new(response.cumulative_qty),
      venue_created_at: response.timestamp,
      leaves_qty: Decimal.new(0)
    )
  end

  defp expire!(cid, response) do
    cid
    |> find_by_and_update(
      status: :expired,
      venue_order_id: response.id,
      venue_created_at: response.timestamp,
      avg_price: response.avg_price,
      cumulative_qty: response.cumulative_qty,
      leaves_qty: response.leaves_qty
    )
  end

  defp open!(cid, response) do
    cid
    |> find_by_and_update(
      status: :open,
      venue_order_id: response.id,
      venue_created_at: response.timestamp,
      avg_price: response.avg_price,
      leaves_qty: response.leaves_qty,
      cumulative_qty: response.cumulative_qty
    )
  end

  defp error!(cid, reason) do
    cid
    |> find_by_and_update(
      status: :error,
      error_reason: reason,
      leaves_qty: Decimal.new(0)
    )
  end

  defp skip!(cid) do
    cid
    |> find_by_and_update(
      status: :skip,
      leaves_qty: Decimal.new(0)
    )
  end

  defp find_by_and_update(client_id, attrs) do
    {:ok, {old_order, updated_order}} =
      OrderStore.find_by_and_update(
        [client_id: client_id],
        attrs
      )

    {old_order, updated_order}
  end
end
