defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Unhandled do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @derive {Jason.Encoder, only: [:data]}
  defstruct ~w(data)a

  defimpl ProcessAuth.Message do
    def process(message, received_at, state) do
      %Tai.Events.StreamMessageUnhandled{
        venue_id: state.venue,
        msg: message.data,
        received_at: received_at
      }
      |> TaiEvents.warn()

      :ok
    end
  end
end
