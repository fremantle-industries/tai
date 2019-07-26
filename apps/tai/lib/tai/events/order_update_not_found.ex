defmodule Tai.Events.OrderUpdateNotFound do
  alias Tai.Events.OrderUpdateNotFound

  @type t :: %OrderUpdateNotFound{
          client_id: Tai.Trading.Order.client_id(),
          action: atom
        }

  @enforce_keys [:client_id, :action]
  defstruct [:client_id, :action]
end
