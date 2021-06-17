defmodule Tai.NewOrders.Queries.SearchOrderQueryTest do
  use Tai.TestSupport.DataCase, async: false

  test "can filter results by full or partial venue order id" do
    {:ok, order_1} = create_order(%{venue_order_id: "353a6c4b-2ed2-4c98-811f-aa02cbe0530b"})
    {:ok, order_2} = create_order(%{venue_order_id: "353a57df-aa1f-459d-b912-f7d3834ac7d4"})
    {:ok, _order_3} = create_order(%{venue_order_id: "b04cd63f-c178-4b61-a894-b92603231ec7"})

    search_orders_1 = execute_query(order_1.venue_order_id)
    assert length(search_orders_1) == 1
    assert Enum.at(search_orders_1, 0) == order_1

    search_orders_2 = execute_query("53a")
    assert length(search_orders_2) == 2
    assert Enum.at(search_orders_2, 0) == order_1
    assert Enum.at(search_orders_2, 1) == order_2
  end

  test "can filter results by full or partial venue name" do
    {:ok, order_1} = create_order(%{venue: "venue_a"})
    {:ok, order_2} = create_order(%{venue: "venue_a"})
    {:ok, order_3} = create_order(%{venue: "venue_b"})

    search_orders_1 = execute_query("venue_a")
    assert length(search_orders_1) == 2
    assert Enum.at(search_orders_1, 0) == order_1
    assert Enum.at(search_orders_1, 1) == order_2

    search_orders_2 = execute_query("venue")
    assert length(search_orders_2) == 3
    assert Enum.at(search_orders_2, 0) == order_1
    assert Enum.at(search_orders_2, 1) == order_2
    assert Enum.at(search_orders_2, 2) == order_3
  end

  test "can filter results by full or partial credential name" do
    {:ok, order_1} = create_order(%{credential: "credential_a"})
    {:ok, order_2} = create_order(%{credential: "credential_a"})
    {:ok, order_3} = create_order(%{credential: "credential_b"})

    search_orders_1 = execute_query("credential_a")
    assert length(search_orders_1) == 2
    assert Enum.at(search_orders_1, 0) == order_1
    assert Enum.at(search_orders_1, 1) == order_2

    search_orders_2 = execute_query("credential")
    assert length(search_orders_2) == 3
    assert Enum.at(search_orders_2, 0) == order_1
    assert Enum.at(search_orders_2, 1) == order_2
    assert Enum.at(search_orders_2, 2) == order_3
  end

  test "can filter results by full or partial product symbol" do
    {:ok, order_1} = create_order(%{product_symbol: "btc_usd", venue_product_symbol: "ignore"})
    {:ok, order_2} = create_order(%{product_symbol: "btc_usd", venue_product_symbol: "ignore"})
    {:ok, order_3} = create_order(%{product_symbol: "eth_usd", venue_product_symbol: "ignore"})

    search_orders_1 = execute_query("btc_usd")
    assert length(search_orders_1) == 2
    assert Enum.at(search_orders_1, 0) == order_1
    assert Enum.at(search_orders_1, 1) == order_2

    search_orders_2 = execute_query("usd")
    assert length(search_orders_2) == 3
    assert Enum.at(search_orders_2, 0) == order_1
    assert Enum.at(search_orders_2, 1) == order_2
    assert Enum.at(search_orders_2, 2) == order_3
  end

  test "can filter results by full or partial venue product symbol" do
    {:ok, order_1} = create_order(%{product_symbol: "ignore", venue_product_symbol: "BTC-USD"})
    {:ok, order_2} = create_order(%{product_symbol: "ignore", venue_product_symbol: "BTC-USD"})
    {:ok, order_3} = create_order(%{product_symbol: "ignore", venue_product_symbol: "ETH-USD"})

    search_orders_1 = execute_query("BTC-USD")
    assert length(search_orders_1) == 2
    assert Enum.at(search_orders_1, 0) == order_1
    assert Enum.at(search_orders_1, 1) == order_2

    search_orders_2 = execute_query("USD")
    assert length(search_orders_2) == 3
    assert Enum.at(search_orders_2, 0) == order_1
    assert Enum.at(search_orders_2, 1) == order_2
    assert Enum.at(search_orders_2, 2) == order_3
  end

  defp execute_query(search_term) do
    search_term
    |> Tai.NewOrders.Queries.SearchOrdersQuery.call()
    |> Tai.NewOrders.OrderRepo.all()
  end
end
