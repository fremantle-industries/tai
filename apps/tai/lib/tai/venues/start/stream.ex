defmodule Tai.Venues.Start.Stream do
  @type stream :: Tai.Venues.Stream.t()

  @spec start(stream) :: DynamicSupervisor.on_start_child()
  def start(stream) do
    Tai.Venues.StreamsSupervisor.start(stream)
  end
end
