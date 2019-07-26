defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.TransformMessages.UpdateOrders do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @behaviour ProcessAuth.Transformer

  def from_venue(%{"table" => "order", "action" => "update", "data" => data}) do
    {:ok, %ProcessAuth.Messages.UpdateOrders{data: data}}
  end

  def from_venue(_msg), do: {:error, :not_handled}
end
