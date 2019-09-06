defmodule Examples.PingPong.CreateEntryOrder do
  alias Examples.PingPong.Config
  alias Tai.Trading.{Orders, OrderSubmissions}

  @type advisor_id :: Tai.Advisor.advisor_id()
  @type market_quote :: Tai.Markets.Quote.t()
  @type config :: Config.t()
  @type order :: Tai.Trading.Order.t()

  @spec create(advisor_id, market_quote, config) :: {:ok, order}
  def create(advisor_id, market_quote, config) do
    price = entry_price(market_quote, config.product)

    %OrderSubmissions.BuyLimitGtc{
      venue_id: market_quote.venue_id,
      account_id: config.fee.account_id,
      product_symbol: config.product.symbol,
      price: price,
      qty: config.max_qty,
      product_type: config.product.type,
      post_only: true,
      order_updated_callback: {advisor_id, :entry_order}
    }
    |> Orders.create()
  end

  defp entry_price(market_quote, product) do
    market_quote.ask.price
    |> Decimal.cast()
    |> Decimal.sub(product.price_increment)
  end
end
