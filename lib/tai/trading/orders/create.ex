defmodule Tai.Trading.Orders.Create do
  alias Tai.Trading.{
    OrderStore,
    OrderResponses,
    Order,
    Orders,
    BuildOrderFromSubmission
  }

  @type order :: Order.t()
  @type submission :: BuildOrderFromSubmission.submission()

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
    notify_updated_order({:ok, {nil, order}})
  end

  defp notify_updated_order({:ok, {previous_order, order}}) do
    Orders.updated!(previous_order, order)
    order
  end

  defp send(order), do: Tai.Venue.create_order(order)

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :filled} = response},
         order
       ) do
    OrderStore.fill(
      order.client_id,
      response.id,
      response.venue_created_at,
      response.avg_price,
      response.cumulative_qty
    )
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :expired} = response},
         order
       ) do
    OrderStore.expire(
      order.client_id,
      response.id,
      response.venue_created_at,
      response.avg_price,
      response.cumulative_qty,
      response.leaves_qty
    )
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :open} = response},
         order
       ) do
    OrderStore.open(
      order.client_id,
      response.id,
      response.venue_created_at,
      response.avg_price,
      response.cumulative_qty,
      response.leaves_qty
    )
  end

  defp parse_response({:error, reason}, order) do
    OrderStore.create_error(order.client_id, reason)
  end

  defp skip!(client_id), do: OrderStore.skip(client_id)
end
