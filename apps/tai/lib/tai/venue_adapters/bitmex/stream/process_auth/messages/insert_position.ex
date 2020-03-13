defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.InsertPosition do
  alias __MODULE__
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @type t :: %InsertPosition{data: map}

  @enforce_keys ~w(data)a
  defstruct ~w(data)a

  defimpl ProcessAuth.Message do
    def process(_message, _received_at, _state) do
      :ok
    end
  end
end
