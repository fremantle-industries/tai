defmodule Support.Orders do
  import Tai.TestSupport.Helpers

  def setup_orders(start_supervised!) do
    config = Tai.Config.parse()
    start_supervised!.(Tai.TestSupport.Mocks.Server)
    start_supervised!.({TaiEvents, 1})
    start_supervised!.({Tai.Settings, config})
    start_supervised!.({Tai.Orders.Supervisor, config})
    start_supervised!.(Tai.Venues.VenueStore)
  end

  def build_submission(type, extra_attrs \\ %{}) do
    attrs =
      %{
        product_symbol: :btc_usd,
        price: Decimal.new("100.1"),
        qty: Decimal.new("0.1"),
        post_only: true
      }
      |> Map.merge(extra_attrs)

    struct(type, attrs)
  end

  def build_submission_with_callback(type, extra_attrs \\ %{}) do
    attrs = %{order_updated_callback: fire_order_callback(self())} |> Map.merge(extra_attrs)
    build_submission(type, attrs)
  end
end
