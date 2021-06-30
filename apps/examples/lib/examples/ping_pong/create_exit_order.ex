defmodule Examples.PingPong.CreateExitOrder do
  alias Examples.PingPong.Config
  alias Tai.NewOrders.Submissions

  @type advisor_name :: Tai.Advisor.advisor_name()
  @type config :: Config.t()
  @type order :: Tai.NewOrders.Order.t()

  @spec create(advisor_name, prev :: order, updated :: order, config) :: {:ok, order}
  def create(advisor_name, prev_entry_order, updated_entry_order, config) do
    price = exit_price(updated_entry_order, config.product)
    qty = Decimal.sub(updated_entry_order.cumulative_qty, prev_entry_order.cumulative_qty)
    venue = updated_entry_order.venue
    credential = updated_entry_order.credential

    %Submissions.SellLimitGtc{
      venue: venue,
      credential: credential,
      venue_product_symbol: updated_entry_order.venue_product_symbol,
      product_symbol: updated_entry_order.product_symbol,
      price: price,
      qty: qty,
      product_type: updated_entry_order.product_type,
      post_only: true,
      order_updated_callback: {advisor_name, :exit_order}
    }
    |> Tai.NewOrders.create()
  end

  defp exit_price(updated_entry_order, product) do
    updated_entry_order.price |> Decimal.add(product.price_increment)
  end
end
