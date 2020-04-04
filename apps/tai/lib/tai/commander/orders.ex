defmodule Tai.Commander.Orders do
  @type order :: Tai.Trading.Order.t()

  @spec get :: [order]
  def get do
    Tai.Trading.OrderStore.all()
    |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))
  end
end
