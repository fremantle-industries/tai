defmodule Support.OrderSubmissions do
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
end
