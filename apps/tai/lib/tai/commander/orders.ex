defmodule Tai.Commander.Orders do
  @type search_term :: Tai.Orders.search_term()
  @type order :: Tai.Orders.Order.t()

  @spec get(search_term, list) :: [order]
  def get(search_term, opts \\ []) do
    Tai.Orders.search(search_term, opts)
  end
end
