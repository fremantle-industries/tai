defmodule Tai.VenueAdapters.Ftx.Stream.UpdateOrder do
  @date_format "{ISO:Extended}"

  def apply(
    %{"clientId" => client_id, "createdAt" => created_at} = msg,
    received_at,
    state
  ) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)

    with {:ok, type} <- transition_type(msg) do
      merged_attrs = {msg, type}
                     |> transition_attrs()
                     |> Map.put(:last_received_at, last_received_at)
                     |> Map.put(:last_venue_timestamp, venue_timestamp)
                     |> Map.put(:__type__, type)

      Tai.Orders.OrderTransitionWorker.apply(client_id, merged_attrs)
    else
      {:error, :invalid_state} ->
        warn_unhandled(msg, last_received_at, state)
    end
  end

  def apply(msg, received_at, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()
    warn_unhandled(msg, last_received_at, state)
  end

  defp warn_unhandled(venue_order, last_received_at, state) do
    TaiEvents.warning(%Tai.Events.StreamMessageOrderUpdateUnhandled{
      venue_id: state.venue,
      msg: venue_order,
      received_at: last_received_at
    })
  end

  @new "new"
  @open "open"
  @closed "closed"

  defp transition_type(%{"status" => status}) when status == @new, do: {:ok, :open}
  defp transition_type(%{"status" => status}) when status == @open, do: {:ok, :partial_fill}
  defp transition_type(%{"status" => status, "filledSize" => f, "size" => s}) when status == @closed and f != s, do: {:ok, :cancel}
  defp transition_type(%{"status" => status, "filledSize" => f, "size" => s}) when status == @closed and f == s, do: {:ok, :fill}
  defp transition_type(_), do: {:error, :invalid_state}

  defp transition_attrs({msg, type}) do
    case type do
      s when s == :cancel ->
        %{}

      s when s == :open or s == :partial_fill ->
        venue_order_id = venue_order_id!(msg)
        cumulative_qty = cumulative_qty!(msg)
        leaves_qty = leaves_qty!(msg)

        %{
          venue_order_id: venue_order_id,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
        }

      s when s == :fill ->
        venue_order_id = venue_order_id!(msg)
        cumulative_qty =  cumulative_qty!(msg)

        %{
          venue_order_id: venue_order_id,
          cumulative_qty: cumulative_qty
        }
    end
  end

  defp venue_order_id!(msg) do
    msg |> Map.fetch!("id") |> Integer.to_string()
  end

  defp cumulative_qty!(msg) do
    {:ok, cumulative_qty} = msg |> Map.fetch!("filledSize") |> Decimal.cast()
    cumulative_qty
  end

  defp leaves_qty!(msg) do
    {:ok, leaves_qty} = msg |> Map.fetch!("remainingSize") |> Decimal.cast()
    leaves_qty
  end
end
