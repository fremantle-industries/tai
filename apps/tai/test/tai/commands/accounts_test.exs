defmodule Tai.Commands.AccountsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows the accounts for each venue with a non-zero balance" do
    mock_account(:test_exchange_a, :main, :btc, 0.1, 1.81227740)

    mock_account(
      :test_exchange_a,
      :main,
      :eth,
      "0.000000000000000000",
      "0.000000000000200000"
    )

    mock_account(:test_exchange_a, :main, :ltc, "0.00000000", "0.03000000")

    mock_account(:test_exchange_b, :main, :btc, 0.1, 1.81227740)

    mock_account(
      :test_exchange_b,
      :main,
      :eth,
      "0.000000000000000000",
      "0.000000000000200000"
    )

    mock_account(:test_exchange_b, :main, :ltc, "0.00000000", "0.03000000")

    assert capture_io(&Tai.CommandsHelper.accounts/0) == """
           +-----------------+------------+-------+----------------------+----------------------+----------------------+
           |           Venue | Credential | Asset |                 Free |               Locked |               Equity |
           +-----------------+------------+-------+----------------------+----------------------+----------------------+
           | test_exchange_a |       main |   btc |           0.10000000 |           1.81227740 |           1.91227740 |
           | test_exchange_a |       main |   eth | 0.000000000000000000 | 0.000000000000200000 | 0.000000000000200000 |
           | test_exchange_a |       main |   ltc |           0.00000000 |           0.03000000 |           0.03000000 |
           | test_exchange_b |       main |   btc |           0.10000000 |           1.81227740 |           1.91227740 |
           | test_exchange_b |       main |   eth | 0.000000000000000000 | 0.000000000000200000 | 0.000000000000200000 |
           | test_exchange_b |       main |   ltc |           0.00000000 |           0.03000000 |           0.03000000 |
           +-----------------+------------+-------+----------------------+----------------------+----------------------+\n
           """
  end

  test "shows an empty table when there are no accounts" do
    assert capture_io(&Tai.CommandsHelper.accounts/0) == """
           +-------+------------+-------+------+--------+--------+
           | Venue | Credential | Asset | Free | Locked | Equity |
           +-------+------------+-------+------+--------+--------+
           |     - |          - |     - |    - |      - |      - |
           +-------+------------+-------+------+--------+--------+\n
           """
  end
end
