defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.TransformMessages.NoOp do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @behaviour ProcessAuth.Transformer

  @ok {:ok, %ProcessAuth.Messages.NoOp{}}

  def from_venue(%{"table" => "order", "action" => "insert"}), do: @ok
  def from_venue(%{"table" => "transact"}), do: @ok
  def from_venue(%{"table" => "execution"}), do: @ok
  def from_venue(%{"table" => "wallet"}), do: @ok
  def from_venue(%{"table" => "margin"}), do: @ok
  def from_venue(%{"table" => "position"}), do: @ok
  def from_venue(_msg), do: {:error, :not_handled}
end
