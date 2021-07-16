defmodule Tai.Commander.OrdersCount do
  @type search_term :: Tai.Orders.search_term()

  @spec get(search_term) :: non_neg_integer
  def get(search_term) do
    Tai.Orders.search_count(search_term)
  end
end
