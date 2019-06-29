defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Unhandled do
  @derive {Jason.Encoder, only: [:data]}
  defstruct ~w(data)a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.SubMessage,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Unhandled do
  def process(message, state) do
    %Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: message
    }
    |> Tai.Events.warn()

    {:ok, state}
  end
end
