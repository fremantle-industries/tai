defmodule Tai.Trading.NotifyOrderUpdate do
  alias Tai.Orders.Order

  @type order :: Order.t()

  @deprecated "Use Tai.Orders.Services.NotifyUpdate.notify!/2 instead."
  @spec notify!(order | nil, order) :: :ok | {:error, :noproc}
  def notify!(previous, updated) do
    Tai.Orders.Services.NotifyUpdate.notify!(previous, updated)
  end
end
