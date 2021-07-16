defmodule Tai.Orders.SearchTest do
  use Tai.TestSupport.DataCase, async: false

  test "returns the oldest 25 orders by default" do
    orders = create_test_orders(26)

    search_orders = Tai.Orders.search(nil)
    assert length(search_orders) == 25
    assert Enum.at(search_orders, 0) == Enum.at(orders, 0)
    assert Enum.at(search_orders, 24) == Enum.at(orders, 24)
  end

  test "can paginate results with a custom page & size" do
    orders = create_test_orders(4)

    search_orders_1 = Tai.Orders.search(nil, page: 1, page_size: 2)
    assert length(search_orders_1) == 2
    assert Enum.at(search_orders_1, 0) == Enum.at(orders, 0)
    assert Enum.at(search_orders_1, 1) == Enum.at(orders, 1)

    search_orders_2 = Tai.Orders.search(nil, page: 2, page_size: 2)
    assert length(search_orders_2) == 2
    assert Enum.at(search_orders_2, 0) == Enum.at(orders, 2)
    assert Enum.at(search_orders_2, 1) == Enum.at(orders, 3)
  end

  test "can filter results with a search term" do
    {:ok, order_1} = create_order(%{venue: "venue_a"})
    {:ok, _order_2} = create_order(%{venue: "venue_b"})

    search_orders = Tai.Orders.search("venue_a")
    assert length(search_orders) == 1
    assert Enum.at(search_orders, 0) == order_1
  end

  defp create_test_orders(count) do
    1
    |> Range.new(count)
    |> Enum.map(fn _n ->
      {:ok, order} = create_order(%{})
      order
    end)
  end
end
