defmodule Tai.NewOrders.OrderCallback do
  @enforce_keys ~w[client_id callback]a
  defstruct ~w[client_id callback]a

  defimpl Stored.Item do
    def key(order_callback), do: order_callback.client_id
  end
end
