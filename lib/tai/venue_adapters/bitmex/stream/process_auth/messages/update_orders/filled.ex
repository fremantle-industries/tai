defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Filled do
  defstruct ~w(
    account
    avg_px
    cl_ord_id
    cum_qty
    leaves_qty
    ord_status
    order_id
    symbol
    timestamp
    working_indicator
  )a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.SubMessage,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Filled do
  alias Tai.VenueAdapters.Bitmex

  @date_format "{ISO:Extended}"

  def process(message, state) do
    message.cl_ord_id
    |> case do
      "gtc-" <> id ->
        client_id = Bitmex.ClientId.from_base64(id)
        received_at = Timex.now()
        venue_timestamp = message.timestamp |> Timex.parse!(@date_format)
        cumulative_qty = message.cum_qty |> Decimal.cast()

        %Tai.Trading.OrderStore.Actions.PassiveFill{
          client_id: client_id,
          cumulative_qty: cumulative_qty,
          last_received_at: received_at,
          last_venue_timestamp: venue_timestamp
        }
        |> Tai.Trading.OrderStore.update()
        |> notify(:passive_fill, client_id)

      _ ->
        :ignore
    end

    {:ok, state}
  end

  defp notify({:ok, {old, updated}}, _, _) do
    Tai.Trading.Orders.updated!(old, updated)
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
