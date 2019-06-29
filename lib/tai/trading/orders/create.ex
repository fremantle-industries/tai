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

  defp send_to_venue(order) do
    result = Tai.Venue.create_order(order)
    {result, order}
  end

  defp parse_response({
         {:ok, %OrderResponses.CreateAccepted{} = response},
         order
       }) do
    result =
      %OrderStore.Actions.AcceptCreate{
        client_id: order.client_id,
        venue_order_id: response.id,
        last_received_at: response.received_at,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:accept_create, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :open} = response},
         order
       }) do
    result =
      %OrderStore.Actions.Open{
        client_id: order.client_id,
        venue_order_id: response.id,
        avg_price: response.avg_price,
        cumulative_qty: response.cumulative_qty,
        leaves_qty: response.leaves_qty,
        last_received_at: response.received_at,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:open, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :filled} = response},
         order
       }) do
    result =
      %OrderStore.Actions.Fill{
        client_id: order.client_id,
        venue_order_id: response.id,
        avg_price: response.avg_price,
        cumulative_qty: response.cumulative_qty,
        last_received_at: response.received_at,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:fill, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :expired} = response},
         order
       }) do
    result =
      %OrderStore.Actions.Expire{
        client_id: order.client_id,
        venue_order_id: response.id,
        avg_price: response.avg_price,
        cumulative_qty: response.cumulative_qty,
        leaves_qty: response.leaves_qty,
        last_received_at: response.received_at,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:expire, result}
  end

  defp parse_response({
         {:ok, %OrderResponses.Create{status: :rejected} = response},
         order
       }) do
    result =
      %OrderStore.Actions.Reject{
        client_id: order.client_id,
        venue_order_id: response.id,
        last_received_at: response.received_at,
        last_venue_timestamp: response.venue_timestamp
      }
      |> OrderStore.update()

    {:reject, result}
  end

  defp parse_response({{:error, reason}, order}) do
    result =
      %OrderStore.Actions.CreateError{
        client_id: order.client_id,
        reason: reason,
        last_received_at: Timex.now()
      }
      |> OrderStore.update()

    {:create_error, result}
  end

  defp rescue_venue_adapter_error(reason, order) do
    result =
      %OrderStore.Actions.CreateError{
        client_id: order.client_id,
        reason: {:unhandled, reason},
        last_received_at: Timex.now()
      }
      |> OrderStore.update()

    {:create_error, result}
  end

  defp skip!(client_id) do
    result = %OrderStore.Actions.Skip{client_id: client_id} |> OrderStore.update()
    {:skip, result}
  end
end
