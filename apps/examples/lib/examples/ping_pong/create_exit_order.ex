defmodule Examples.PingPong.CreateExitOrder do
  alias Examples.PingPong.Config
  alias Tai.Trading.{Orders, OrderSubmissions}

  @type advisor_id :: Tai.Advisor.advisor_id()
  @type config :: Config.t()
  @type order :: Tai.Trading.Order.t()

  @spec create(advisor_id, order, config) :: {:ok, order}
  def create(advisor_id, entry_order, config) do
    price = exit_price(entry_order, config.product)

    %OrderSubmissions.SellLimitGtc{
      venue_id: entry_order.venue_id,
      account_id: entry_order.account_id,
      product_symbol: entry_order.product_symbol,
      price: price,
      qty: config.max_qty,
      product_type: entry_order.product_type,
      post_only: true,
      order_updated_callback: {advisor_id, :exit_order}
    }
    |> Orders.create()
  end

  defp exit_price(entry_order, product) do
    entry_order.price |> Decimal.add(product.price_increment)
  end
end
