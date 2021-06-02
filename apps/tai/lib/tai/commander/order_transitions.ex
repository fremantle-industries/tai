defmodule Tai.Commander.OrderTransitions do
  @type client_id :: Tai.NewOrders.Order.client_id()
  @type search_term :: Tai.NewOrders.search_term()
  @type order :: Tai.NewOrders.Order.t()

  @spec get(client_id, search_term, list) :: [order]
  def get(client_id, search_term, opts \\ []) do
    Tai.NewOrders.search_transitions(client_id, search_term, opts)
  end
end
