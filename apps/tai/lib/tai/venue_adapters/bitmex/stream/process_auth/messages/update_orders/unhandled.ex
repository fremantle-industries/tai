defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Unhandled do
  @derive {Jason.Encoder, only: [:data]}
  defstruct ~w(data)a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Unhandled do
  def process(message, received_at, state) do
    %Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: message.data,
      received_at: received_at
    }
    |> Tai.Events.warn()

    :ok
  end
end
