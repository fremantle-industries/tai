defmodule Tai.Orders.SearchCountTest do
  use Tai.TestSupport.DataCase, async: false

  test "returns the count of orders matching the search query" do
    {:ok, _order_1} = create_order(%{venue: "venue_a"})
    {:ok, _order_2} = create_order(%{venue: "venue_a"})
    {:ok, _order_3} = create_order(%{venue: "venue_b"})

    assert Tai.Orders.search_count(nil) == 3

    assert Tai.Orders.search_count("venue_a") == 2
  end
end
