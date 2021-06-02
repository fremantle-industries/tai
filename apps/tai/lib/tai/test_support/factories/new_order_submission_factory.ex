defmodule Tai.TestSupport.Factories.NewOrderSubmissionFactory do
  def build_submission(type, extra_attrs \\ %{}) do
    attrs =
      %{
        product_symbol: "btc_usd",
        venue_product_symbol: "BTC-USD",
        product_type: :spot,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        leaves_qty: Decimal.new("0.1"),
        cumulative_qty: Decimal.new("0"),
        post_only: true,
        close: false
      }
      |> Map.merge(extra_attrs)

    struct(type, attrs)
  end

  def build_submission_with_callback(type, extra_attrs \\ %{}) do
    attrs =
      Map.merge(
        %{order_updated_callback: fire_order_callback(self())},
        extra_attrs
      )

    build_submission(type, attrs)
  end

  def fire_order_callback(pid) do
    fn previous_order, updated_order, transition ->
      send(pid, {:callback_fired, previous_order, updated_order, transition})
    end
  end
end
