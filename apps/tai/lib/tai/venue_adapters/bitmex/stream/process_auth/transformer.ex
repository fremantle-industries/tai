defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Transformer do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages

  @type msg :: map
  @type action ::
          Messages.UpdateOrders.t()
          | Messages.NoOp.t()
          | Messages.Unhandled.t()

  @callback from_venue(msg) :: {:ok, action} | {:error, :not_handled}
end
