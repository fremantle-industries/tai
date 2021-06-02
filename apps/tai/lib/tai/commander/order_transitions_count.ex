defmodule Tai.Commander.OrderTransitionsCount do
  @type client_id :: Tai.NewOrders.Order.client_id()
  @type search_term :: Tai.NewOrders.search_term()

  @spec get(client_id, search_term) :: non_neg_integer
  def get(client_id, search_term) do
    Tai.NewOrders.search_transitions_count(client_id, search_term)
  end
end
