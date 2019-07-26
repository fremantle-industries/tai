defmodule ExamplesSupport.E2E.CreateAndCancelPendingOrder do
  alias Tai.TestSupport.Mocks
  import Tai.TestSupport.Mock

  @venue :test_exchange_a
  @account :mock_account
  @product_symbol :btc_usd
  @venue_order_id "e116de5f-8d14-491f-a794-0f94fbcdd7c1"

  def seed_mock_responses(:create_and_cancel_pending_order) do
    Mocks.Responses.Products.for_venue(
      :test_exchange_a,
      [
        %{symbol: :btc_usd},
        %{symbol: :ltc_usd}
      ]
    )

    Mocks.Responses.Products.for_venue(
      :test_exchange_b,
      [
        %{symbol: :eth_usd},
        %{symbol: :ltc_usd}
      ]
    )

    Mocks.Responses.Orders.GoodTillCancel.open(
      @venue_order_id,
      %Tai.Trading.OrderSubmissions.BuyLimitGtc{
        venue_id: @venue,
        account_id: @account,
        product_symbol: @product_symbol,
        product_type: :spot,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: true
      }
    )

    Mocks.Responses.Orders.GoodTillCancel.canceled(@venue_order_id)
  end

  def push_stream_market_data(
        {:create_and_cancel_pending_order, :snapshot, venue_id, product_symbol}
      )
      when venue_id == @venue and product_symbol == @product_symbol do
    push_market_data_snapshot(
      %Tai.Markets.Location{
        venue_id: @venue,
        product_symbol: @product_symbol
      },
      %{100.1 => 1.1},
      %{100.11 => 1.2}
    )
  end

  def advisor_group_config(:create_and_cancel_pending_order) do
    [
      advisor: Examples.CreateAndCancelPendingOrder.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      products: "test_exchange_a.btc_usd"
    ]
  end
end
