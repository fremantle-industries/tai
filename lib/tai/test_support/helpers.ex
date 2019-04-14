defmodule Tai.TestSupport.Helpers do
  def test_venue_adapters_maker_taker_fees,
    do: :test_venue_adapters_maker_taker_fees |> filter()

  def test_venue_adapters_create_order_error,
    do: :test_venue_adapters_create_order_error |> filter()

  def test_venue_adapters_create_order_gtc,
    do: :test_venue_adapters_create_order_gtc |> filter()

  def test_venue_adapters_create_order_fok,
    do: :test_venue_adapters_create_order_fok |> filter()

  def test_venue_adapters_create_order_ioc,
    do: :test_venue_adapters_create_order_ioc |> filter()

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
