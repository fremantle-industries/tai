defmodule Tai.Commander.Orders do
  @type order :: Tai.Orders.Order.t()

  @spec get :: [order]
  def get do
    Tai.Orders.Queries.FindAll.execute()
    |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))
  end
end
