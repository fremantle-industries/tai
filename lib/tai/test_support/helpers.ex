defmodule Tai.TestSupport.Helpers do
  def test_venue_adapters_products,
    do: :test_venue_adapters_products |> filter()

  def test_venue_adapters_asset_balances,
    do: :test_venue_adapters_asset_balances |> filter()

  def test_venue_adapters_maker_taker_fees,
    do: :test_venue_adapters_maker_taker_fees |> filter()

  def test_venue_adapters_create_order_gtc_open,
    do: :test_venue_adapters_create_order_gtc_open |> filter()

  def test_venue_adapters_create_order_gtc_accepted,
    do: :test_venue_adapters_create_order_gtc_accepted |> filter()

  def test_venue_adapters_create_order_fok,
    do: :test_venue_adapters_create_order_fok |> filter()

  def test_venue_adapters_create_order_ioc,
    do: :test_venue_adapters_create_order_ioc |> filter()

  def test_venue_adapters_create_order_close,
    do: :test_venue_adapters_create_order_close |> filter()

  def test_venue_adapters_create_order_error,
    do: :test_venue_adapters_create_order_error |> filter()

  def test_venue_adapters_create_order_error_insufficient_balance,
    do: :test_venue_adapters_create_order_error_insufficient_balance |> filter()

  def test_venue_adapters_cancel_order,
    do: :test_venue_adapters_cancel_order |> filter()

  def test_venue_adapters_cancel_order_accepted,
    do: :test_venue_adapters_cancel_order_accepted |> filter()

  def test_venue_adapters_cancel_order_error_timeout,
    do: :test_venue_adapters_cancel_order_error_timeout |> filter()

  def test_venue_adapters_cancel_order_error_overloaded,
    do: :test_venue_adapters_cancel_order_error_overloaded |> filter()

  def test_venue_adapters_cancel_order_error_nonce_not_increasing,
    do: :test_venue_adapters_cancel_order_error_nonce_not_increasing |> filter()

  def test_venue_adapters_cancel_order_error_rate_limited,
    do: :test_venue_adapters_cancel_order_error_rate_limited |> filter()

  def test_venue_adapters_cancel_order_error_unhandled,
    do: :test_venue_adapters_cancel_order_error_unhandled |> filter()

  def test_venue_adapters_with_positions,
    do: :test_venue_adapters_with_positions |> filter()

  def test_venue_adapters do
    Confex.resolve_env!(:tai)
    test_adapters = Application.get_env(:tai, :test_venue_adapters)
    config = Tai.Config.parse(venues: test_adapters)
    Tai.Venues.Config.parse_adapters(config)
  end

  def fire_order_callback(pid) do
    fn previous_order, updated_order ->
      send(pid, {:callback_fired, previous_order, updated_order})
    end
  end

  defp filter(type), do: test_venue_adapters() |> Map.take(type |> venues())
  defp venues(type), do: Application.get_env(:tai, type, [])
end
