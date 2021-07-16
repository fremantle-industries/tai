defmodule Tai.Orders.GetTest do
  use Tai.TestSupport.DataCase, async: false

  test ".get_by_client_id/1 returns the order when found and nil otherwise" do
    {:ok, order_1} = create_order()
    {:ok, _order_2} = create_order()

    assert Tai.Orders.get_by_client_id(order_1.client_id) == order_1
    assert Tai.Orders.get_by_client_id(Ecto.UUID.generate()) == nil
  end

  test ".get_by_client_ids/1 returns orders matching the given client ids" do
    {:ok, order_1} = create_order()
    {:ok, order_2} = create_order()

    matching_orders = Tai.Orders.get_by_client_ids([order_1.client_id, order_2.client_id])
    assert Enum.member?(matching_orders, order_1)
    assert Enum.member?(matching_orders, order_2)

    assert Tai.Orders.get_by_client_ids([Ecto.UUID.generate()]) == []
  end
end
