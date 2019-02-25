defmodule Tai.Commands.Helper.OrdersTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows items in ascending order from when they were enqueued" do
    {:ok, btc_usd_order} =
      %Tai.Trading.OrderSubmissions.BuyLimitFok{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: Decimal.new("12999.99"),
        qty: Decimal.new("1.1")
      }
      |> Tai.Trading.OrderStore.add()

    btc_usd_order_client_id = "#{btc_usd_order.client_id |> String.slice(0..5)}..."

    {:ok, ltc_usd_order} =
      %Tai.Trading.OrderSubmissions.SellLimitFok{
        venue_id: :test_exchange_b,
        account_id: :main,
        product_symbol: :ltc_usd,
        price: Decimal.new("75.23"),
        qty: Decimal.new("1.0")
      }
      |> Tai.Trading.OrderStore.add()

    ltc_usd_order_client_id = "#{ltc_usd_order.client_id |> String.slice(0..5)}..."

    assert capture_io(&Tai.Commands.Helper.orders/0) == """
           +-----------------+---------+---------+------+-------+----------+-----------+-----+------------+----------------+---------------+----------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           |           Venue | Account |  Symbol | Side |  Type |    Price | Avg Price | Qty | Leaves Qty | Cumulative Qty | Time in Force |   Status | Client ID | Venue Order ID | Enqueued At | Last Received At | Last Venue Timestamp | Updated At | Error Reason |
           +-----------------+---------+---------+------+-------+----------+-----------+-----+------------+----------------+---------------+----------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           | test_exchange_a |    main | btc_usd |  buy | limit | 12999.99 |         0 | 1.1 |        1.1 |              0 |           fok | enqueued | #{
             btc_usd_order_client_id
           } |                |         now |                  |                      |            |              |
           | test_exchange_b |    main | ltc_usd | sell | limit |    75.23 |         0 | 1.0 |        1.0 |              0 |           fok | enqueued | #{
             ltc_usd_order_client_id
           } |                |         now |                  |                      |            |              |
           +-----------------+---------+---------+------+-------+----------+-----------+-----+------------+----------------+---------------+----------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+\n
           """
  end

  test "shows an empty table when there are no orders" do
    assert capture_io(&Tai.Commands.Helper.orders/0) == """
           +-------+---------+--------+------+------+-------+-----------+-----+------------+----------------+---------------+--------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           | Venue | Account | Symbol | Side | Type | Price | Avg Price | Qty | Leaves Qty | Cumulative Qty | Time in Force | Status | Client ID | Venue Order ID | Enqueued At | Last Received At | Last Venue Timestamp | Updated At | Error Reason |
           +-------+---------+--------+------+------+-------+-----------+-----+------------+----------------+---------------+--------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           |     - |       - |      - |    - |    - |     - |         - |   - |          - |              - |             - |      - |         - |              - |           - |                - |                    - |          - |            - |
           +-------+---------+--------+------+------+-------+-----------+-----+------------+----------------+---------------+--------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+\n
           """
  end
end
