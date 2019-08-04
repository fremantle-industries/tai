defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.NoOp do
  alias __MODULE__

  @type t :: %NoOp{}

  defstruct []
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.NoOp do
  def process(_message, _received_at, state), do: {:ok, state}
end
