defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.PartiallyFilled do
  defstruct ~w(
      account
      cl_ord_id
      leaves_qty
      ord_status
      order_id
      order_qty
      price
      symbol
      text
      timestamp
      transact_time
      working_indicator
    )a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.SubMessage,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.PartiallyFilled do
  alias Tai.VenueAdapters.Bitmex

  @date_format "{ISO:Extended}"

  def process(message, received_at, state) do
    message.cl_ord_id
    |> case do
      "gtc-" <> id ->
        client_id = Bitmex.ClientId.from_base64(id)
        venue_timestamp = message.timestamp |> Timex.parse!(@date_format)
        leaves_qty = message.leaves_qty |> Decimal.cast()
        cumulative_qty = message.order_qty |> Decimal.cast() |> Decimal.sub(leaves_qty)

        %Tai.Trading.OrderStore.Actions.PassivePartialFill{
          client_id: client_id,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
          last_received_at: received_at,
          last_venue_timestamp: venue_timestamp
        }
        |> Tai.Trading.OrderStore.update()
        |> notify(:passive_partial_fill, client_id)

      _ ->
        :ignore
    end

    {:ok, state}
  end

  defp notify({:ok, {old, updated}}, _, _) do
    Tai.Trading.NotifyOrderUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required}}, action, client_id) do
    Tai.Events.info(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: client_id,
      action: action,
      was: was,
      required: required
    })
  end

  defp notify({:error, :not_found}, action, client_id) do
    Tai.Events.info(%Tai.Events.OrderUpdateNotFound{
      client_id: client_id,
      action: action
    })
  end
end
