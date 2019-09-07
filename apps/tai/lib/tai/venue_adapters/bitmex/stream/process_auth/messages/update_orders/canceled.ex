defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Canceled do
  defstruct ~w(
    account
    cl_ord_id
    leaves_qty
    ord_status
    order_id
    symbol
    text
    timestamp
    working_indicator
  )a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Canceled do
  alias Tai.VenueAdapters.Bitmex

  @date_format "{ISO:Extended}"

  def process(message, received_at, _state) do
    message.cl_ord_id
    |> case do
      "gtc-" <> id ->
        client_id = Bitmex.ClientId.from_base64(id)
        venue_timestamp = message.timestamp |> Timex.parse!(@date_format)

        %Tai.Trading.OrderStore.Actions.PassiveCancel{
          client_id: client_id,
          last_received_at: received_at,
          last_venue_timestamp: venue_timestamp
        }
        |> Tai.Trading.OrderStore.update()
        |> notify()

      _ ->
        :ignore
    end

    :ok
  end

  defp notify({:ok, {old, updated}}) do
    Tai.Trading.NotifyOrderUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required, %action_name{} = action}}) do
    Tai.Events.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: action.client_id,
      action: action_name,
      last_received_at: action.last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    })
  end

  defp notify({:error, {:not_found, %action_name{} = action}}) do
    Tai.Events.warn(%Tai.Events.OrderUpdateNotFound{
      client_id: action.client_id,
      action: action_name
    })
  end
end
