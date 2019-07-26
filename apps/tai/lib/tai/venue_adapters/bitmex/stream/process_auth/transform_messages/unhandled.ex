defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.TransformMessages.Unhandled do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @behaviour ProcessAuth.Transformer

  def from_venue(msg), do: {:ok, %ProcessAuth.Messages.Unhandled{msg: msg}}
end
