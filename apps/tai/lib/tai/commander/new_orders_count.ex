defmodule Tai.Commander.NewOrdersCount do
  @type search_term :: Tai.NewOrders.search_term()

  @spec get(search_term) :: non_neg_integer
  def get(search_term) do
    Tai.NewOrders.search_count(search_term)
  end
end
