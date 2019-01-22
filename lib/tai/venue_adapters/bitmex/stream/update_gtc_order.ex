defmodule Tai.VenueAdapters.Bitmex.Stream.UpdateGtcOrder do
  alias Tai.VenueAdapters.Bitmex.ClientId

  def update(venue_client_id, venue_order) do
    client_id = venue_client_id |> ClientId.from_base64()
    attrs = build_attrs(venue_order)

    with {:ok, {prev_order, updated_order}} <-
           Tai.Trading.OrderStore.find_by_and_update(
             [client_id: client_id],
             attrs
           ) do
      Tai.Trading.Orders.updated!(prev_order, updated_order)
    end
  end

  @format "{ISO:Extended}"
  defp build_attrs(venue_order) do
    status =
      venue_order
      |> Map.fetch!("ordStatus")
      |> Tai.VenueAdapters.Bitmex.OrderStatus.from_venue_status(:ignore)

    leaves_qty =
      venue_order
      |> Map.fetch!("leavesQty")
      |> Decimal.new()

    venue_updated_at =
      venue_order
      |> Map.fetch!("timestamp")
      |> Timex.parse!(@format)

    attrs = [status: status, leaves_qty: leaves_qty, venue_updated_at: venue_updated_at]

    if status != :canceled do
      cumulative_qty =
        venue_order
        |> Map.fetch!("cumQty")
        |> Decimal.new()

      avg_price =
        venue_order
        |> Map.fetch!("avgPx")
        |> Tai.Utils.Decimal.from()

      attrs
      |> Keyword.put(:cumulative_qty, cumulative_qty)
      |> Keyword.put(:avg_price, avg_price)
    else
      attrs
    end
  end
end
