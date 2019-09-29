defmodule Examples.PingPong.CreateExitOrder do
  alias Examples.PingPong.Config
  alias Tai.Trading.{Orders, OrderSubmissions}

  @type advisor_name :: Tai.Advisor.advisor_name()
  @type config :: Config.t()
  @type order :: Tai.Trading.Order.t()

  @spec create(advisor_name, prev :: order, updated :: order, config) :: {:ok, order}
  def create(advisor_name, prev_entry_order, updated_entry_order, config) do
    price = exit_price(updated_entry_order, config.product)
    qty = Decimal.sub(updated_entry_order.cumulative_qty, prev_entry_order.cumulative_qty)

    %OrderSubmissions.SellLimitGtc{
      venue_id: updated_entry_order.venue_id,
      account_id: updated_entry_order.account_id,
      product_symbol: updated_entry_order.product_symbol,
      price: price,
      qty: qty,
      product_type: updated_entry_order.product_type,
      post_only: true,
      order_updated_callback: {advisor_name, :exit_order}
    }
    |> Orders.create()
  end

  defp exit_price(updated_entry_order, product) do
    updated_entry_order.price |> Decimal.add(product.price_increment)
  end
end
