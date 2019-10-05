defmodule Examples.PingPong.CreateEntryOrder do
  alias Examples.PingPong.{Config, EntryPrice}
  alias Tai.Trading.{Orders, OrderSubmissions}

  @type advisor_name :: Tai.Advisor.advisor_name()
  @type market_quote :: Tai.Markets.Quote.t()
  @type config :: Config.t()
  @type order :: Tai.Trading.Order.t()

  @spec create(advisor_name, market_quote, config) :: {:ok, order}
  def create(advisor_name, market_quote, config, orders_provider \\ Orders) do
    price = EntryPrice.calculate(market_quote, config.product)

    %OrderSubmissions.BuyLimitGtc{
      venue_id: market_quote.venue_id,
      account_id: config.fee.account_id,
      product_symbol: config.product.symbol,
      price: price,
      qty: config.max_qty,
      product_type: config.product.type,
      post_only: true,
      order_updated_callback: {advisor_name, :entry_order}
    }
    |> orders_provider.create()
  end
end
