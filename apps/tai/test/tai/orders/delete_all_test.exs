defmodule Tai.Orders.DeleteAllTest do
  use Tai.TestSupport.DataCase, async: false

  test ".delete_all/1 clears the orders" do
    {:ok, _order_1} = create_order()
    {:ok, _order_2} = create_order()

    assert Tai.Orders.OrderRepo.aggregate(Tai.Orders.Order, :count) == 2

    assert Tai.Orders.delete_all() == {2, nil}
    assert Tai.Orders.OrderRepo.aggregate(Tai.Orders.Order, :count) == 0
  end
end
