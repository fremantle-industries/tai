defmodule Tai.TestSupport.Helpers do
  def test_venue_adapters do
    Confex.resolve_env!(:tai)
    test_adapters = Application.get_env(:tai, :test_venue_adapters)
    config = Tai.Config.parse(venues: test_adapters)
    Tai.Venues.Config.parse_adapters(config)
  end

  @test_venue_adapters_create_order Application.get_env(
                                      :tai,
                                      :test_venue_adapters_create_order,
                                      []
                                    )
  def test_venue_adapters_create_order,
    do: test_venue_adapters() |> Map.take(@test_venue_adapters_create_order)

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
