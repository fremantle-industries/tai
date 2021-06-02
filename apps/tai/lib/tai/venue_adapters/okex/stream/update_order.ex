defmodule Tai.VenueAdapters.OkEx.Stream.UpdateOrder do
  alias Tai.NewOrders.OrderTransitionWorker

  @date_format "{ISO:Extended:Z}"

  def apply(
        client_id,
        %{"state" => order_state, "timestamp" => timestamp} = msg,
        received_at,
        state
      ) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()

    with {:ok, type} <- transition_type(order_state) do
      {:ok, venue_timestamp} = Timex.parse(timestamp, @date_format)
      merged_attrs = msg
                     |> transition_attrs()
                     |> Map.put(:last_received_at, last_received_at)
                     |> Map.put(:last_venue_timestamp, venue_timestamp)
                     |> Map.put(:__type__, type)

      OrderTransitionWorker.apply(client_id, merged_attrs)
    else
      # TODO: Need to write unit test for :invalid_client_id
      {:error, :invalid_state} ->
        warn_unhandled(msg, last_received_at, state)
    end
  end

  def apply(_client_id, msg, received_at, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()
    warn_unhandled(msg, last_received_at, state)
  end

  defp warn_unhandled(msg, last_received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: last_received_at
    })
  end

  @canceled "-1"
  @pending "0"
  @partially_filled "1"
  @fully_filled "2"

  defp transition_type(s) when s == @canceled, do: {:ok, :cancel}
  defp transition_type(s) when s == @pending, do: {:ok, :open}
  defp transition_type(s) when s == @partially_filled, do: {:ok, :partial_fill}
  defp transition_type(s) when s == @fully_filled, do: {:ok, :fill}
  defp transition_type(_), do: {:error, :invalid_state}

  defp transition_attrs(%{"state" => order_state} = msg) do
    case order_state do
      s when s == @canceled ->
        %{}

      s when s == @pending or s == @partially_filled ->
        venue_order_id = Map.fetch!(msg, "order_id")
        size = Map.fetch!(msg, "size")
        cumulative_qty = msg |> filled() |> Decimal.new()
        leaves_qty = size |> Decimal.new() |> Decimal.sub(cumulative_qty)

        %{
          venue_order_id: venue_order_id,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
        }

      s when s == @fully_filled ->
        venue_order_id = Map.fetch!(msg, "order_id")
        cumulative_qty = msg |> filled() |> Decimal.new()

        %{
          venue_order_id: venue_order_id,
          cumulative_qty: cumulative_qty
        }
    end
  end

  defp filled(msg) do
    Map.get(msg, "filled_size") || Map.fetch!(msg, "filled_qty")
  end
end
