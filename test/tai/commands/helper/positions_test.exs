defmodule Tai.Commands.Helper.PositionsTest do
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
        cost: Decimal.new("10.1"),
        qty: Decimal.new(10)
      )
      |> Tai.Trading.PositionStore.add()

    {:ok, _} =
      Tai.Trading.Position
      |> struct(
        venue_id: :venue_b,
        account_id: :account_b,
        product_symbol: :ltc_usd,
        cost: Decimal.new("0.2"),
        qty: Decimal.new(2)
      )
      |> Tai.Trading.PositionStore.add()

    assert capture_io(&Tai.Commands.Helper.positions/0) == """
           +---------+-----------+---------+------+-----+
           |   Venue |   Account | Product | Cost | Qty |
           +---------+-----------+---------+------+-----+
           | venue_a | account_a | btc_usd | 10.1 |  10 |
           | venue_b | account_b | ltc_usd |  0.2 |   2 |
           +---------+-----------+---------+------+-----+\n
           """
  end

  test "shows an empty table when there are no positions" do
    assert capture_io(&Tai.Commands.Helper.positions/0) == """
           +-------+---------+---------+------+-----+
           | Venue | Account | Product | Cost | Qty |
           +-------+---------+---------+------+-----+
           |     - |       - |       - |    - |   - |
           +-------+---------+---------+------+-----+\n
           """
  end
end
