defmodule Tai.Orders.OrderCallback do
  @type server :: GenServer.server()
  @type callback :: function | server | {server, term}
  @type t :: %__MODULE__{
          client_id: term,
          callback: callback
        }

  @enforce_keys ~w[client_id callback]a
  defstruct ~w[client_id callback]a

  defimpl Stored.Item do
    def key(order_callback), do: order_callback.client_id
  end
end
