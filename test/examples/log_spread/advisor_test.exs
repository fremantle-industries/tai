defmodule Examples.Advisors.LogSpread.AdvisorTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Tai.TestSupport.Mock

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    mock_products()
    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  test "logs the bid/ask spread" do
    start_supervised!({
      Examples.Advisors.LogSpread.Advisor,
      [
        group_id: :log_spread,
        advisor_id: :btc_usd,
        order_books: %{test_exchange_a: [:btc_usd]},
        store: %{}
      ]
    })

    log_msg =
      capture_log(fn ->
        mock_snapshot(
          :test_exchange_a,
          :btc_usd,
          %{6500.1 => 1.1},
          %{6500.11 => 1.2}
        )

        :timer.sleep(100)
      end)

    assert log_msg =~ ~r/\[spread:test_exchange_a,btc_usd,0.01,6500.1,6500.11\]/
  end

  def mock_products() do
    Tai.TestSupport.Mocks.Responses.Products.for_exchange(
      :test_exchange_a,
      [
        %{symbol: :btc_usd},
        %{symbol: :ltc_usd}
      ]
    )

    Tai.TestSupport.Mocks.Responses.Products.for_exchange(
      :test_exchange_b,
      [
        %{symbol: :eth_usd},
        %{symbol: :ltc_usd}
      ]
    )
  end
end
