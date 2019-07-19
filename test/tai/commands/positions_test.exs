defmodule Tai.Commands.PositionsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows positions ordered by venue & account" do
    {:ok, _} =
      Tai.Trading.Position
      |> struct(
        venue_id: :venue_a,
        account_id: :account_a,
        product_symbol: :btc_usd,
        open: true,
        avg_entry_price: Decimal.new("10.1"),
        qty: Decimal.new(10),
        init_margin: Decimal.new(0),
        init_margin_req: Decimal.new(0),
        maint_margin: Decimal.new(0),
        maint_margin_req: Decimal.new(0),
        realised_pnl: Decimal.new(0),
        unrealised_pnl: Decimal.new(0)
      )
      |> Tai.Trading.PositionStore.add()

    {:ok, _} =
      Tai.Trading.Position
      |> struct(
        venue_id: :venue_b,
        account_id: :account_b,
        product_symbol: :ltc_usd,
        open: true,
        avg_entry_price: Decimal.new("0.2"),
        qty: Decimal.new(2),
        init_margin: Decimal.new(0),
        init_margin_req: Decimal.new(0),
        maint_margin: Decimal.new(0),
        maint_margin_req: Decimal.new(0),
        realised_pnl: Decimal.new(0),
        unrealised_pnl: Decimal.new(0)
      )
      |> Tai.Trading.PositionStore.add()

    assert capture_io(&Tai.CommandsHelper.positions/0) == """
           +---------+-----------+---------+------+-----------------+-----+-------------+-----------------+--------------+------------------+--------------+----------------+
           |   Venue |   Account | Product | Open | Avg Entry Price | Qty | Init Margin | Init Margin Req | Maint Margin | Maint Margin Req | Realised Pnl | Unrealised Pnl |
           +---------+-----------+---------+------+-----------------+-----+-------------+-----------------+--------------+------------------+--------------+----------------+
           | venue_a | account_a | btc_usd | true |            10.1 |  10 |           0 |               0 |            0 |                0 |            0 |              0 |
           | venue_b | account_b | ltc_usd | true |             0.2 |   2 |           0 |               0 |            0 |                0 |            0 |              0 |
           +---------+-----------+---------+------+-----------------+-----+-------------+-----------------+--------------+------------------+--------------+----------------+\n
           """
  end

  test "shows an empty table when there are no positions" do
    assert capture_io(&Tai.CommandsHelper.positions/0) == """
           +-------+---------+---------+------+-----------------+-----+-------------+-----------------+--------------+------------------+--------------+----------------+
           | Venue | Account | Product | Open | Avg Entry Price | Qty | Init Margin | Init Margin Req | Maint Margin | Maint Margin Req | Realised Pnl | Unrealised Pnl |
           +-------+---------+---------+------+-----------------+-----+-------------+-----------------+--------------+------------------+--------------+----------------+
           |     - |       - |       - |    - |               - |   - |           - |               - |            - |                - |            - |              - |
           +-------+---------+---------+------+-----------------+-----+-------------+-----------------+--------------+------------------+--------------+----------------+\n
           """
  end
end
