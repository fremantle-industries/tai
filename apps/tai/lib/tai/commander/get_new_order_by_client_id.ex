defmodule Tai.Commander.GetNewOrderByClientId do
  @type client_id :: Tai.NewOrders.Order.client_id()
  @type order :: Tai.NewOrders.Order.t()

  @spec get(client_id) :: order
  def get(client_id) do
    Tai.NewOrders.get_by_client_id(client_id)
  end
end
