defmodule Tai.Commander.DeleteAllOrders do
  @spec execute() :: {non_neg_integer, nil}
  def execute do
    Tai.Orders.delete_all()
  end
end
