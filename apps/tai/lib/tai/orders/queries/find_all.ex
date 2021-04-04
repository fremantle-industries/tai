defmodule Tai.Orders.Queries.FindAll do
  @type order :: Tai.Orders.Order.t()

  @spec execute :: [order]
  def execute do
    Tai.Orders.OrderStore.all()
  end
end
