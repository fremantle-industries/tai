defmodule Examples.PingPong.CreateEntryOrder do
  alias Examples.PingPong.{Config, EntryPrice}
  alias Tai.Orders.Submissions

  @type advisor_process :: Tai.Advisor.advisor_name()
  @type market_quote :: Tai.Markets.Quote.t()
  @type config :: Config.t()
  @type order :: Tai.Orders.Order.t()

  @spec create(advisor_process, market_quote, config) :: {:ok, order}
  def create(advisor_process, market_quote, config) do
    price = EntryPrice.calculate(market_quote, config.product)
    venue = market_quote.venue_id |> Atom.to_string()
    credential = config.fee.credential_id |> Atom.to_string()
    product_symbol = config.product.symbol |> Atom.to_string()

    %Submissions.BuyLimitGtc{
      venue: venue,
      credential: credential,
      venue_product_symbol: config.product.venue_symbol,
      product_symbol: product_symbol,
      price: price,
      qty: config.max_qty,
      product_type: config.product.type,
      post_only: true,
      order_updated_callback: {advisor_process, :entry_order}
    }
    |> Tai.Orders.create()
  end
end
