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
          |> send_to_venue()
          |> parse_response()
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

  defp notify_initial_updated_order(order), do: Orders.updated!(nil, order)

  defp notify_updated_order({_, {:ok, {prev, current}}}), do: Orders.updated!(prev, current)
  defp notify_updated_order({:accept_create, {:error, {:invalid_status, _, _}}}), do: :ok

  def send_to_venue(order) do
    result = Tai.Venue.create_order(order)
    {result, order}
  end

  defp parse_response({
         {:ok, %OrderResponses.CreateAccepted{} = response},
         order
       }) do
    result =
      OrderStore.accept_create(
        order.client_id,
        response.id,
        response.received_at,
        response.venue_timestamp
      )

    {:accept_create, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :open} = response},
         order
       }) do
    result =
      OrderStore.open(
        order.client_id,
        response.id,
        response.avg_price,
        response.cumulative_qty,
        response.leaves_qty,
        response.received_at,
        response.venue_timestamp
      )

    {:open, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :filled} = response},
         order
       }) do
    result =
      OrderStore.fill(
        order.client_id,
        response.id,
        response.avg_price,
        response.cumulative_qty,
        response.received_at,
        response.venue_timestamp
      )

    {:fill, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :expired} = response},
         order
       }) do
    result =
      OrderStore.expire(
        order.client_id,
        response.id,
        response.avg_price,
        response.cumulative_qty,
        response.leaves_qty,
        response.received_at,
        response.venue_timestamp
      )

    {:expire, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :rejected} = response},
         order
       }) do
    result =
      OrderStore.reject(
        order.client_id,
        response.id,
        response.received_at,
        response.venue_timestamp
      )

    {:reject, result}
  end

  defp parse_response({{:error, reason}, order}) do
    result = OrderStore.create_error(order.client_id, reason, Timex.now())
    {:create_error, result}
  end

  defp rescue_venue_adapter_error(reason, order) do
    result = OrderStore.create_error(order.client_id, {:unhandled, reason}, Timex.now())
    {:create_error, result}
  end

  defp skip!(client_id) do
    result = OrderStore.skip(client_id)
    {:skip, result}
  end
end
