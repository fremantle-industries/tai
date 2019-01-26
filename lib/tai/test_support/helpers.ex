defmodule Tai.TestSupport.Helpers do
  def test_venue_adapters do
    Confex.resolve_env!(:tai)
    test_adapters = Application.get_env(:tai, :test_venue_adapters)
    config = Tai.Config.parse(venues: test_adapters)
    Tai.Venues.Config.parse_adapters(config)
  end

  @test_venue_adapters_with_positions Application.get_env(
                                        :tai,
                                        :test_venue_adapters_with_positions
                                      )
  def test_venue_adapters_with_positions do
    test_venue_adapters()
    |> Enum.reduce(
      %{},
      fn {id, adapter}, acc ->
        if Enum.member?(@test_venue_adapters_with_positions, id) do
          Map.put(acc, id, adapter)
        else
          acc
        end
      end
    )
  end

  def fire_order_callback(pid) do
    fn previous_order, updated_order ->
      send(pid, {:callback_fired, previous_order, updated_order})
    end
  end
end
