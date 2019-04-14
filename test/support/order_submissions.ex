defmodule Support.OrderSubmissions do
  import Tai.TestSupport.Helpers

  def build(type, extra_attrs \\ %{}) do
    attrs =
      %{
        venue_id: :test_exchange_a,
        account_id: :main,
        product_symbol: :btc_usd,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: true
      }
      |> Map.merge(extra_attrs)

    struct(type, attrs)
  end

  def build_with_callback(type, extra_attrs \\ %{}) do
    attrs = %{order_updated_callback: fire_order_callback(self())} |> Map.merge(extra_attrs)
    build(type, attrs)
  end
end
