defmodule Tai.NewOrders.SearchTransitionsCountTest do
  use Tai.TestSupport.DataCase, async: false

  test "returns the count of order transitions matching the search query" do
    {:ok, order} = create_order()
    {:ok, _order_transition_1} = create_order_transition(order.client_id, %{}, :cancel)
    {:ok, _order_transition_2} = create_order_transition(order.client_id, %{}, :cancel)
    {:ok, _order_transition_3} = create_order_transition(order.client_id, %{}, :cancel)

    assert Tai.NewOrders.search_transitions_count(order.client_id, nil) == 3
  end
end
