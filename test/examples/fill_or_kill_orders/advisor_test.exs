defmodule Examples.Advisors.FillOrKillOrders.AdvisorTest do
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
    Tai.Settings.enable_send_orders!()

    start_supervised!({
      Examples.Advisors.FillOrKillOrders.Advisor,
      [
        group_id: :fill_or_kill_orders,
        advisor_id: :btc_usd,
        products: [
          struct(
            Tai.Exchanges.Product,
            %{exchange_id: :test_exchange_a, symbol: :btc_usd}
          )
        ],
        config: %{}
      ]
    })

    :ok
  end

  test "creates a single fill or kill order" do
    Tai.TestSupport.Mocks.Orders.FillOrKill.filled(
      symbol: :btc_usd,
      price: Decimal.new(100.1),
      original_size: Decimal.new(0.1)
    )

    log_msg =
      capture_log(fn ->
        push_market_feed_snapshot(
          %Tai.Markets.Location{
            venue_id: :test_exchange_a,
            product_symbol: :btc_usd
          },
          %{100.1 => 1.1},
          %{100.11 => 1.2}
        )

        :timer.sleep(100)
      end)

    assert log_msg =~
             ~r/\[order:.{36,36},enqueued,test_exchange_a,main,btc_usd,buy,limit,fok,100.1,0.1,\]/

    assert log_msg =~ ~r/filled order %Tai.Trading.Order{/
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
