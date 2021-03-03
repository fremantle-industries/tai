defmodule Tai.TestSupport.Helpers do
  def test_venue_adapters_products do
    :test_venue_adapters_products |> filter()
  end

  def test_venue_adapters_accounts do
    :test_venue_adapters_accounts |> filter()
  end

  def test_venue_adapters_accounts_error do
    :test_venue_adapters_accounts_error |> filter()
  end

  def test_venue_adapters_maker_taker_fees do
    :test_venue_adapters_maker_taker_fees |> filter()
  end

  def test_venue_adapters_create_order_gtc_open do
    :test_venue_adapters_create_order_gtc_open |> filter()
  end

  def test_venue_adapters_create_order_gtc_accepted do
    :test_venue_adapters_create_order_gtc_accepted |> filter()
  end

  def test_venue_adapters_create_order_fok do
    :test_venue_adapters_create_order_fok |> filter()
  end

  def test_venue_adapters_create_order_ioc do
    :test_venue_adapters_create_order_ioc |> filter()
  end

  def test_venue_adapters_create_order_ioc_accepted do
    :test_venue_adapters_create_order_ioc_accepted |> filter()
  end

  def test_venue_adapters_create_order_close do
    :test_venue_adapters_create_order_close |> filter()
  end

  def test_venue_adapters_create_order_error do
    :test_venue_adapters_create_order_error |> filter()
  end

  def test_venue_adapters_create_order_error_insufficient_balance do
    :test_venue_adapters_create_order_error_insufficient_balance |> filter()
  end

  def test_venue_adapters_amend_order do
    :test_venue_adapters_amend_order |> filter()
  end

  def test_venue_adapters_amend_bulk_order do
    :test_venue_adapters_amend_bulk_order |> filter()
  end

  def test_venue_adapters_cancel_order do
    :test_venue_adapters_cancel_order |> filter()
  end

  def test_venue_adapters_cancel_order_accepted do
    :test_venue_adapters_cancel_order_accepted |> filter()
  end

  def test_venue_adapters_cancel_order_error_not_found do
    :test_venue_adapters_cancel_order_error_not_found |> filter()
  end

  def test_venue_adapters_cancel_order_error_timeout do
    :test_venue_adapters_cancel_order_error_timeout |> filter()
  end

  def test_venue_adapters_cancel_order_error_overloaded do
    :test_venue_adapters_cancel_order_error_overloaded |> filter()
  end

  def test_venue_adapters_cancel_order_error_nonce_not_increasing do
    :test_venue_adapters_cancel_order_error_nonce_not_increasing |> filter()
  end

  def test_venue_adapters_cancel_order_error_rate_limited do
    :test_venue_adapters_cancel_order_error_rate_limited |> filter()
  end

  def test_venue_adapters_cancel_order_error_unhandled do
    :test_venue_adapters_cancel_order_error_unhandled |> filter()
  end

  def test_venue_adapters_with_positions do
    :test_venue_adapters_with_positions |> filter()
  end

  def test_venue_adapters do
    Confex.resolve_env!(:tai)
    test_adapters = Application.get_env(:tai, :test_venue_adapters)
    config = Tai.Config.parse(venues: test_adapters)
    Tai.Venues.Config.parse(config)
  end

  def test_venue_adapter(id) do
    test_venue_adapters() |> Enum.find(&(&1.id == id))
  end

  defp filter(type) do
    test_venue_adapters()
    |> Enum.filter(fn v ->
      type
      |> venues()
      |> Enum.member?(v.id)
    end)
  end

  defp venues(type), do: Application.get_env(:tai, type, [])

  def fire_order_callback(pid) do
    fn previous_order, updated_order ->
      send(pid, {:callback_fired, previous_order, updated_order})
    end
  end
end
