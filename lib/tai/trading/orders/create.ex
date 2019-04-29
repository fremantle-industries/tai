defmodule Tai.Trading.Orders.Create do
  alias Tai.Trading.{
    OrderStore,
    OrderResponses,
    Order,
    Orders,
    OrderSubmissions
  }

  @type order :: Order.t()
  @type submission :: OrderSubmissions.Factory.submission()

  @spec create(submission) :: {:ok, order}
  def create(submission) do
    {:ok, order} = OrderStore.enqueue(submission)
    notify_initial_updated_order(order)

    Task.async(fn ->
      if Tai.Settings.send_orders?() do
        try do
          order
          |> send_to_venue
          |> parse_response(order)
          |> notify_updated_order()
        rescue
          e ->
            {e, __STACKTRACE__}
            |> rescue_venue_adapter_error(order)
            |> notify_updated_order()
        end
      else
        order.client_id
        |> skip!
        |> notify_updated_order()
      end
    end)

    {:ok, order}
  end

  defp notify_initial_updated_order(order), do: notify_updated_order({:ok, {nil, order}})

  defp notify_updated_order({:ok, {previous_order, order}}) do
    Orders.updated!(previous_order, order)
    order
  end

  defdelegate send_to_venue(order), to: Tai.Venue, as: :create_order

  defp parse_response(
         {:ok, %OrderResponses.CreateAccepted{} = response},
         order
       ) do
    OrderStore.accept_create(
      order.client_id,
      response.id,
      response.received_at,
      response.venue_timestamp
    )
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :open} = response},
         order
       ) do
    OrderStore.open(
      order.client_id,
      response.id,
      response.avg_price,
      response.cumulative_qty,
      response.leaves_qty,
      response.received_at,
      response.venue_timestamp
    )
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :filled} = response},
         order
       ) do
    OrderStore.fill(
      order.client_id,
      response.id,
      response.avg_price,
      response.cumulative_qty,
      response.received_at,
      response.venue_timestamp
    )
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :expired} = response},
         order
       ) do
    OrderStore.expire(
      order.client_id,
      response.id,
      response.avg_price,
      response.cumulative_qty,
      response.leaves_qty,
      response.received_at,
      response.venue_timestamp
    )
  end

  defp parse_response(
         {:ok, %OrderResponses.Create{status: :rejected} = response},
         order
       ) do
    OrderStore.reject(
      order.client_id,
      response.id,
      response.received_at,
      response.venue_timestamp
    )
  end

  defp parse_response({:error, reason}, order) do
    OrderStore.create_error(order.client_id, reason, Timex.now())
  end

  defp rescue_venue_adapter_error(reason, order) do
    OrderStore.create_error(order.client_id, {:unhandled, reason}, Timex.now())
  end

  defdelegate skip!(client_id), to: OrderStore, as: :skip
end
