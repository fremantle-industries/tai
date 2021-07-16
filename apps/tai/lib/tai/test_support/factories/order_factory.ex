defmodule Tai.TestSupport.Factories.OrderFactory do
  alias Tai.Orders.{
    Order,
    OrderCallback,
    OrderCallbackStore,
    OrderRepo
  }

  alias Tai.TestSupport.Factories.OrderSubmissionFactory

  def create_order(attrs \\ %{}) do
    merged_attrs = generate_order_attrs() |> Map.merge(attrs)

    %Order{}
    |> Order.changeset(merged_attrs)
    |> OrderRepo.insert()
  end

  def update_order(order, attrs) do
    order
    |> Order.changeset(attrs)
    |> OrderRepo.update()
  end

  def create_order_with_callback(attrs \\ %{}) do
    with {:ok, order} <- create_order(attrs) do
      order_callback = %OrderCallback{
        client_id: order.client_id,
        callback: OrderSubmissionFactory.fire_order_callback(self())
      }

      {:ok, _} = OrderCallbackStore.put(order_callback)
      {:ok, order}
    end
  end

  defp generate_order_attrs do
    %{
      client_id: Ecto.UUID.generate(),
      venue_order_id: Ecto.UUID.generate(),
      venue: "venue_a",
      credential: "main",
      product_symbol: "btc_usd",
      venue_product_symbol: "BTC-USD",
      product_type: :spot,
      status: :enqueued,
      side: :buy,
      type: :limit,
      price: Decimal.new("10200.1"),
      qty: Decimal.new("2.1"),
      leaves_qty: Decimal.new("2.1"),
      cumulative_qty: Decimal.new(0),
      post_only: true,
      close: false,
      time_in_force: :gtc
    }
  end
end
