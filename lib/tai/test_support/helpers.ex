defmodule Tai.TestSupport.Helpers do
  def test_venue_adapters do
    Confex.resolve_env!(:tai)
    test_adapters = Application.get_env(:tai, :test_venue_adapters)
    config = Tai.Config.parse(venues: test_adapters)
    Tai.Venues.Config.parse_adapters(config)
  end

  @test_venue_adapters_maker_taker_fees Application.get_env(
                                          :tai,
                                          :test_venue_adapters_maker_taker_fees,
                                          []
                                        )
  def test_venue_adapters_maker_taker_fees,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_maker_taker_fees)

  @test_venue_adapters_create_order_error Application.get_env(
                                            :tai,
                                            :test_venue_adapters_create_order_error,
                                            []
                                          )
  def test_venue_adapters_create_order_error,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_create_order_error)

  @test_venue_adapters_create_order_gtc Application.get_env(
                                          :tai,
                                          :test_venue_adapters_create_order_gtc,
                                          []
                                        )
  def test_venue_adapters_create_order_gtc,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_create_order_gtc)

  @test_venue_adapters_create_order_fok Application.get_env(
                                          :tai,
                                          :test_venue_adapters_create_order_fok,
                                          []
                                        )
  def test_venue_adapters_create_order_fok,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_create_order_fok)

  @test_venue_adapters_create_order_ioc Application.get_env(
                                          :tai,
                                          :test_venue_adapters_create_order_ioc,
                                          []
                                        )
  def test_venue_adapters_create_order_ioc,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_create_order_ioc)

  @test_venue_adapters_with_positions Application.get_env(
                                        :tai,
                                        :test_venue_adapters_with_positions,
                                        []
                                      )
  def test_venue_adapters_with_positions,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_with_positions)

  def fire_order_callback(pid) do
    fn previous_order, updated_order ->
      send(pid, {:callback_fired, previous_order, updated_order})
    end
  end
end
