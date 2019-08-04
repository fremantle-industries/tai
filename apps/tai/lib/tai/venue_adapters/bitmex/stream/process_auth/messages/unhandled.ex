defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.Unhandled do
  alias __MODULE__

  @type t :: %Unhandled{msg: map}

  @enforce_keys ~w(msg)a
  defstruct ~w(msg)a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.Unhandled do
  def process(_message, _received_at, state), do: {:ok, state}
end
