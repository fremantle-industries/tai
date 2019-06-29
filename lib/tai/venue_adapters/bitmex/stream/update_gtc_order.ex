defmodule Tai.VenueAdapters.Bitmex.Stream.UpdateGtcOrder do
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.Trading.OrderStore

  @date_format "{ISO:Extended}"

  def update(venue_client_id, %{"ordStatus" => venue_status} = venue_order) do
    client_id = venue_client_id |> ClientId.from_base64()

    venue_status
    |> from_venue_status()
    |> passive_update(client_id, venue_order)
    |> notify
  end

  defp from_venue_status(venue_status) do
    Tai.VenueAdapters.Bitmex.OrderStatus.from_venue_status(venue_status, :ignore)
  end

  defp passive_update(
         :filled,
         client_id,
         %{"timestamp" => timestamp, "cumQty" => cum_qty}
       ) do
    received_at = Timex.now()
    venue_timestamp = timestamp |> Timex.parse!(@date_format)
    cumulative_qty = cum_qty |> Tai.Utils.Decimal.from()

    result =
      %OrderStore.Actions.PassiveFill{
        client_id: client_id,
        cumulative_qty: cumulative_qty,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :passive_fill, result}
  end

  defp passive_update(
         :open,
         client_id,
         %{
           "timestamp" => timestamp,
           "avgPx" => avg_px,
           "cumQty" => cum_qty,
           "leavesQty" => lvs_qty
         }
       ) do
    received_at = Timex.now()
    venue_timestamp = timestamp |> Timex.parse!(@date_format)
    avg_price = avg_px |> Tai.Utils.Decimal.from()
    cumulative_qty = cum_qty |> Tai.Utils.Decimal.from()
    leaves_qty = lvs_qty |> Tai.Utils.Decimal.from()

    result =
      %OrderStore.Actions.PassivePartialFill{
        client_id: client_id,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :passive_partial_fill, result}
  end

  defp passive_update(:canceled, client_id, %{"timestamp" => timestamp}) do
    received_at = Timex.now()
    venue_timestamp = timestamp |> Timex.parse!(@date_format)

    result =
      %OrderStore.Actions.PassiveCancel{
        client_id: client_id,
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      }
      |> OrderStore.update()

    {client_id, :passive_cancel, result}
  end

  defp notify({_, _, {:ok, {old, updated}}}) do
    Tai.Trading.Orders.updated!(old, updated)
  end

  defp notify({client_id, action, {:error, {:invalid_status, was, required}}}) do
    Tai.Events.info(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      action: action,
      was: was,
      required: required
    })
  end

  defp notify({client_id, action, {:error, :not_found}}) do
    Tai.Events.info(%Tai.Events.OrderUpdateNotFound{
      client_id: client_id,
      action: action
    })
  end
end
