defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdatePosition do
  alias __MODULE__
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @type t :: %UpdatePosition{data: map}

  @enforce_keys ~w(data)a
  defstruct ~w(data)a

  defimpl ProcessAuth.Message do
    def process(message, _received_at, _state) do
      :ok
    end
  end
end
