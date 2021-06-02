defmodule Tai.Commander.GetNewOrdersByClientIds do
  @type client_id :: Tai.NewOrders.Order.client_id()
  @type order :: Tai.NewOrders.Order.t()

  @spec get([client_id]) :: [order]
  def get(client_ids) do
    Tai.NewOrders.get_by_client_ids(client_ids)
  end
end
