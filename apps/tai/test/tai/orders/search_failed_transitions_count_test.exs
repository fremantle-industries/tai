defmodule Tai.Orders.SearchFailedTransitionsCountTest do
  use Tai.TestSupport.DataCase, async: false

  test "returns the count of failed order transitions matching the search query" do
    {:ok, order} = create_order()
    {:ok, _} = create_failed_order_transition(order.client_id, :error, "cancel")
    {:ok, _} = create_failed_order_transition(order.client_id, :error, "cancel")
    {:ok, _} = create_failed_order_transition(order.client_id, :error, "cancel")

    assert Tai.Orders.search_failed_transitions_count(order.client_id, nil) == 3
  end
end
