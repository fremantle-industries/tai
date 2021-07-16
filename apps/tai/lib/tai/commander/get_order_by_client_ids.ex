defmodule Tai.Commander.GetOrdersByClientIds do
  @type client_id :: Tai.Orders.Order.client_id()
  @type order :: Tai.Orders.Order.t()

  @spec get([client_id]) :: [order]
  def get(client_ids) do
    Tai.Orders.get_by_client_ids(client_ids)
  end
end
