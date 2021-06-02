defmodule Tai.Commander.NewOrders do
  @type search_term :: Tai.NewOrders.search_term()
  @type order :: Tai.NewOrders.Order.t()

  @spec get(search_term, list) :: [order]
  def get(search_term, opts \\ []) do
    Tai.NewOrders.search(search_term, opts)
  end
end
