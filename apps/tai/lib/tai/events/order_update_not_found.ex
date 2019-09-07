defmodule Tai.Events.OrderUpdateNotFound do
  alias __MODULE__

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %OrderUpdateNotFound{
          client_id: client_id,
          action: atom
        }

  @enforce_keys ~w(client_id action)a
  defstruct ~w(client_id action)a
end
