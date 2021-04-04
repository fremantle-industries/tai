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

        %Tai.Orders.Transitions.PassiveCancel{
          client_id: client_id,
          last_received_at: received_at,
          last_venue_timestamp: venue_timestamp
        }
        |> Tai.Orders.OrderStore.update()
        |> notify()

      _ ->
        :ignore
    end

    :ok
  end

  defp notify({:ok, {old, updated}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required, %transition_name{} = transition}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      was: was,
      required: required,
      client_id: transition.client_id,
      transition: transition_name,
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    })
  end

  defp notify({:error, {:not_found, %transition_name{} = transition}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateNotFound{
      client_id: transition.client_id,
      transition: transition_name
    })
  end
end
