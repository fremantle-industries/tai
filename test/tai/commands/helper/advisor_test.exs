defmodule Tai.Commands.Helper.AdvisorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "shows detailed information about the advisor" do
    mock_product(%{exchange_id: :exchange_a, symbol: :btc_usdt})
    mock_product(%{exchange_id: :exchange_b, symbol: :eth_usdt})

    assert capture_io(fn ->
             Tai.Commands.Helper.advisor(:log_spread, :exchange_a_btc_usdt)
           end) ==
             """
             Group ID: log_spread
             Advisor ID: exchange_a_btc_usdt
             Config: %{}
             Status: unstarted
             PID: -
             """
  end

  test "shows empty fields when there is no advisor in the group" do
    assert capture_io(fn ->
             Tai.Commands.Helper.advisor(:log_spread, :exchange_a_btc_usdt)
           end) ==
             """
             Group ID: -
             Advisor ID: -
             Config: -
             Status: -
             PID: -
             """
  end
end
