defmodule Tai.Commander.DeleteAllOrders do
  @spec execute() :: {non_neg_integer, nil}
  def execute do
    Tai.NewOrders.delete_all()
  end
end
