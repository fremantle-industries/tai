defmodule Tai.VenueAdapters.Bitmex.Stream.UpdateOrder do
  alias Tai.VenueAdapters.Bitmex.ClientId

  def apply(
    %{"clOrdID" => cl_ord_id, "ordStatus" => order_status, "timestamp" => venue_timestamp} = msg,
    received_at,
    state
  ) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()

    with {:ok, client_id} <- extract_client_id(cl_ord_id),
         {:ok, type} <- transition_type(order_status) do
      merged_attrs = msg
                     |> transition_attrs()
                     |> Map.put(:last_received_at, last_received_at)
                     |> Map.put(:last_venue_timestamp, venue_timestamp)
                     |> Map.put(:__type__, type)

      Tai.Orders.OrderTransitionWorker.apply(client_id, merged_attrs)
    else
      {:error, :invalid_client_id} ->
        warn_invalid_client_id(cl_ord_id, last_received_at, state)

      {:error, :invalid_state} ->
        warn_unhandled(msg, last_received_at, state)
    end
  end

  def apply(msg, received_at, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()
    warn_unhandled(msg, last_received_at, state)
  end

  defp warn_unhandled(msg, last_received_at, state) do
    TaiEvents.warning(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: last_received_at
    })
  end

  defp warn_invalid_client_id(client_id, last_received_at, state) do
    TaiEvents.warning(%Tai.Events.StreamMessageInvalidOrderClientId{
      venue_id: state.venue,
      client_id: client_id,
      received_at: last_received_at
    })
  end

  defp extract_client_id(cl_ord_id) do
    case cl_ord_id do
      "gtc-" <> encoded_client_id -> 
        decoded_client_id = ClientId.from_base64(encoded_client_id)
        {:ok, decoded_client_id}

      _ -> 
        {:error, :invalid_client_id}
    end
  end

  # DEV NOTE: Currently unhandled but not required possible BitMEX order status
  # "PendingNew"
  # "DoneForDay"
  # "Stopped"
  # "PendingCancel"
  # "Expired"
  @canceled "Canceled"
  @new "New"
  @filled "Filled"
  @partially_filled "PartiallyFilled"

  defp transition_type(s) when s == @canceled, do: {:ok, :cancel}
  defp transition_type(s) when s == @new, do: {:ok, :open}
  defp transition_type(s) when s == @partially_filled, do: {:ok, :partial_fill}
  defp transition_type(s) when s == @filled, do: {:ok, :fill}
  defp transition_type(_), do: {:error, :invalid_state}

  defp transition_attrs(%{"ordStatus" => order_status} = msg) do
    case order_status do
      s when s == @canceled ->
        %{}

      s when s == @new or s == @partially_filled ->
        venue_order_id = venue_order_id!(msg)
        cumulative_qty = cumulative_qty!(msg)
        leaves_qty = leaves_qty!(msg)

        %{
          venue_order_id: venue_order_id,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
        }

      s when s == @filled ->
        venue_order_id = venue_order_id!(msg)
        cumulative_qty =  cumulative_qty!(msg)

        %{
          venue_order_id: venue_order_id,
          cumulative_qty: cumulative_qty
        }
    end
  end

  defp venue_order_id!(msg) do
    Map.fetch!(msg, "orderID")
  end

  defp cumulative_qty!(msg) do
    {:ok, cumulative_qty} = msg |> Map.fetch!("cumQty") |> Decimal.cast()
    cumulative_qty
  end

  defp leaves_qty!(msg) do
    {:ok, leaves_qty} = msg |> Map.fetch!("leavesQty") |> Decimal.cast()
    leaves_qty
  end
end
