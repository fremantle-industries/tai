defmodule Examples.Advisors.CreateAndCancelPendingOrder.AdvisorTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Mock
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Mocks.Server)
    mock_product_responses()
    mock_order_responses()
    {:ok, _} = Application.ensure_all_started(:tai)
    Tai.Settings.enable_send_orders!()

    start_supervised!({
      Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
      [
        group_id: :create_and_cancel_open_order,
        advisor_id: :btc_usd,
        products: [
          struct(
            Tai.Venues.Product,
            %{venue_id: :test_exchange_a, symbol: :btc_usd}
          )
        ],
        config: %{}
      ]
    })

    :ok
  end

  test "creates a single limit order and then cancels it" do
    Tai.Events.firehose_subscribe()

    push_market_data_snapshot(
      %Tai.Markets.Location{
        venue_id: :test_exchange_a,
        product_symbol: :btc_usd
      },
      %{100.1 => 1.1},
      %{100.11 => 1.2}
    )

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :open, time_in_force: :gtc}}

    assert_receive {Tai.Event,
                    %Tai.Events.OrderUpdated{status: :pending_cancel, time_in_force: :gtc}}

    assert_receive {Tai.Event, %Tai.Events.OrderUpdated{status: :canceled, time_in_force: :gtc}}
  end

  def mock_order_responses do
    venue_order_id = "e116de5f-8d14-491f-a794-0f94fbcdd7c1"

    Mocks.Responses.Orders.GoodTillCancel.open(
      venue_order_id,
      %Tai.Trading.OrderSubmissions.BuyLimitGtc{
        venue_id: :test_exchange_a,
        account_id: :mock_account,
        product_symbol: :btc_usd,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: true
      }
    )

    Mocks.Responses.Orders.GoodTillCancel.canceled(venue_order_id)
  end

  def mock_product_responses() do
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
