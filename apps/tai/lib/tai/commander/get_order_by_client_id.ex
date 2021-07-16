defmodule Tai.Commander.GetOrderByClientId do
  @type client_id :: Tai.Orders.Order.client_id()
  @type order :: Tai.Orders.Order.t()

  @spec get(client_id) :: order
  def get(client_id) do
    Tai.Orders.get_by_client_id(client_id)
  end
end
