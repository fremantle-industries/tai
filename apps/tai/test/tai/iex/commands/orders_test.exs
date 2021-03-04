defmodule Tai.IEx.Commands.OrdersTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows items in ascending order from when they were enqueued" do
    {:ok, btc_usd_order} =
      %Tai.Trading.OrderSubmissions.BuyLimitFok{
        venue_id: :test_exchange_a,
        credential_id: :main,
        venue_product_symbol: "BTC-USD",
        product_symbol: :btc_usd,
        product_type: :spot,
        price: Decimal.new("12999.99"),
        qty: Decimal.new("1.1")
      }
      |> Tai.Trading.OrderStore.enqueue()

    btc_usd_order_client_id = "#{btc_usd_order.client_id |> String.slice(0..5)}..."

    {:ok, ltc_usd_order} =
      %Tai.Trading.OrderSubmissions.SellLimitFok{
        venue_id: :test_exchange_b,
        credential_id: :main,
        venue_product_symbol: "LTC-USD",
        product_symbol: :ltc_usd,
        product_type: :spot,
        price: Decimal.new("75.23"),
        qty: Decimal.new("1.0")
      }
      |> Tai.Trading.OrderStore.enqueue()

    ltc_usd_order_client_id = "#{ltc_usd_order.client_id |> String.slice(0..5)}..."

    assert capture_io(&Tai.IEx.orders/0) == """
           +-----------------+------------+----------------+--------------+------+-------+----------+-----+------------+----------------+---------------+----------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           |           Venue | Credential | Product Symbol | Product Type | Side |  Type |    Price | Qty | Leaves Qty | Cumulative Qty | Time in Force |   Status | Client ID | Venue Order ID | Enqueued At | Last Received At | Last Venue Timestamp | Updated At | Error Reason |
           +-----------------+------------+----------------+--------------+------+-------+----------+-----+------------+----------------+---------------+----------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           | test_exchange_a |       main |        btc_usd |         spot |  buy | limit | 12999.99 | 1.1 |        1.1 |              0 |           fok | enqueued | #{
             btc_usd_order_client_id
           } |                |         now |                  |                      |            |              |
           | test_exchange_b |       main |        ltc_usd |         spot | sell | limit |    75.23 | 1.0 |        1.0 |              0 |           fok | enqueued | #{
             ltc_usd_order_client_id
           } |                |         now |                  |                      |            |              |
           +-----------------+------------+----------------+--------------+------+-------+----------+-----+------------+----------------+---------------+----------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+\n
           """
  end

  test "shows an empty table when there are no orders" do
    assert capture_io(&Tai.IEx.orders/0) == """
           +-------+------------+----------------+--------------+------+------+-------+-----+------------+----------------+---------------+--------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           | Venue | Credential | Product Symbol | Product Type | Side | Type | Price | Qty | Leaves Qty | Cumulative Qty | Time in Force | Status | Client ID | Venue Order ID | Enqueued At | Last Received At | Last Venue Timestamp | Updated At | Error Reason |
           +-------+------------+----------------+--------------+------+------+-------+-----+------------+----------------+---------------+--------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+
           |     - |          - |              - |            - |    - |    - |     - |   - |          - |              - |             - |      - |         - |              - |           - |                - |                    - |          - |            - |
           +-------+------------+----------------+--------------+------+------+-------+-----+------------+----------------+---------------+--------+-----------+----------------+-------------+------------------+----------------------+------------+--------------+\n
           """
  end
end
