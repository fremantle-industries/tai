defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Created do
  defstruct ~w(
    account
    cl_ord_id
    order_id
    symbol
    timestamp
    working_indicator
  )a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.Created do
  def process(_message, _received_at, _state), do: :ok
end
