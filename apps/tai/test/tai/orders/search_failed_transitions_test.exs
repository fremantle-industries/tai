defmodule Tai.Orders.SearchFailedTransitionsTest do
  use Tai.TestSupport.DataCase, async: false

  test "returns the oldest 25 failed order transitions by default" do
    {:ok, order} = create_order()
    failed_order_transitions = create_test_failed_order_transitions(order, 26)

    search_failed_order_transitions = Tai.Orders.search_failed_transitions(order.client_id, nil)
    assert length(search_failed_order_transitions) == 25
    assert Enum.at(search_failed_order_transitions, 0) == Enum.at(failed_order_transitions, 0)
    assert Enum.at(search_failed_order_transitions, 24) == Enum.at(failed_order_transitions, 24)
  end

  test "can paginate results with a custom page & size" do
    {:ok, order} = create_order()
    failed_order_transitions = create_test_failed_order_transitions(order, 4)

    search_failed_order_transitions_1 = Tai.Orders.search_failed_transitions(order.client_id, nil, page: 1, page_size: 2)
    assert length(search_failed_order_transitions_1) == 2
    assert Enum.at(search_failed_order_transitions_1, 0) == Enum.at(failed_order_transitions, 0)
    assert Enum.at(search_failed_order_transitions_1, 1) == Enum.at(failed_order_transitions, 1)

    search_failed_order_transitions_2 = Tai.Orders.search_failed_transitions(order.client_id, nil, page: 2, page_size: 2)
    assert length(search_failed_order_transitions_2) == 2
    assert Enum.at(search_failed_order_transitions_2, 0) == Enum.at(failed_order_transitions, 2)
    assert Enum.at(search_failed_order_transitions_2, 1) == Enum.at(failed_order_transitions, 3)
  end

  defp create_test_failed_order_transitions(order, count) do
    1
    |> Range.new(count)
    |> Enum.map(fn _n ->
      {:ok, order_transition} = create_failed_order_transition(order.client_id, :error, "cancel")
      order_transition
    end)
  end
end
