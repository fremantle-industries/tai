defmodule Tai.Commander.FailedOrderTransitions do
  @type client_id :: Tai.Orders.Order.client_id()
  @type search_term :: Tai.Orders.search_term()
  @type order :: Tai.Orders.Order.t()

  @spec get(client_id, search_term, list) :: [order]
  def get(client_id, search_term, opts \\ []) do
    Tai.Orders.search_failed_transitions(client_id, search_term, opts)
  end
end
