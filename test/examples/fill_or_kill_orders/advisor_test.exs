defmodule Examples.Advisors.FillOrKillOrders.AdvisorTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Mock
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    mock_product_responses()
    mock_order_response()
    {:ok, _} = Application.ensure_all_started(:tai)
    Tai.Settings.enable_send_orders!()

    start_supervised!({
      Examples.Advisors.FillOrKillOrders.Advisor,
      [
        group_id: :fill_or_kill_orders,
        advisor_id: :btc_usd,
        products: [
          struct(
            Tai.Venues.Product,
            %{exchange_id: :test_exchange_a, symbol: :btc_usd}
          )
        ],
        config: %{}
      ]
    })

    :ok
  end

  test "creates a fill or kill order" do
    Tai.Events.firehose_subscribe()

    push_market_feed_snapshot(
      %Tai.Markets.Location{
        venue_id: :test_exchange_a,
        product_symbol: :btc_usd
      },
      %{100.1 => 1.1},
      %{100.11 => 1.2}
    )

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{
                      status: :enqueued
                    } = enqueued_event}

    assert enqueued_event.cumulative_qty == Decimal.new(0)

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{
                      status: :filled
                    } = filled_event}

    assert filled_event.cumulative_qty == Decimal.new("0.1")
  end

  def mock_order_response do
    Mocks.Responses.Orders.FillOrKill.filled(%Tai.Trading.OrderSubmissions.BuyLimitFok{
      venue_id: :test_exchange_a,
      account_id: :mock_account,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("0.1")
    })
  end

  def mock_product_responses do
    Mocks.Responses.Products.for_exchange(
      :test_exchange_a,
      [
        %{symbol: :btc_usd},
        %{symbol: :ltc_usd}
      ]
    )

    Mocks.Responses.Products.for_exchange(
      :test_exchange_b,
      [
        %{symbol: :eth_usd},
        %{symbol: :ltc_usd}
      ]
    )
  end
end
