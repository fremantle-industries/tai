defmodule Tai.Commander.FailedOrderTransitionsCount do
  @type client_id :: Tai.Orders.Order.client_id()
  @type search_term :: Tai.Orders.search_term()

  @spec get(client_id, search_term) :: non_neg_integer
  def get(client_id, search_term) do
    Tai.Orders.search_failed_transitions_count(client_id, search_term)
  end
end
