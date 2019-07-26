defmodule ExamplesSupport.E2E.FillOrKillOrders do
  alias Tai.TestSupport.Mocks
  import Tai.TestSupport.Mock

  @venue :test_exchange_a
  @account :mock_account
  @product_symbol :btc_usd

  def seed_mock_responses(:fill_or_kill_orders) do
    Mocks.Responses.Products.for_venue(@venue, [%{symbol: :btc_usd}])

    Mocks.Responses.Orders.FillOrKill.filled(%Tai.Trading.OrderSubmissions.BuyLimitFok{
      venue_id: @venue,
      account_id: @account,
      product_symbol: @product_symbol,
      product_type: :spot,
      price: Decimal.new("100.1"),
      qty: Decimal.new("0.1")
    })
  end

  def push_stream_market_data({:fill_or_kill_orders, :snapshot, venue_id, product_symbol})
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

  def advisor_group_config(:fill_or_kill_orders) do
    [
      advisor: Examples.FillOrKillOrders.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      products: "test_exchange_a.btc_usd"
    ]
  end
end
