defmodule Tai.Events.OrderUpdateNotFound do
  alias __MODULE__

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %OrderUpdateNotFound{
          client_id: client_id,
          transition: module
        }

  @enforce_keys ~w[client_id transition]a
  defstruct ~w[client_id transition]a
end
