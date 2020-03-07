defmodule Tai.Venues.StreamsSupervisor do
  use DynamicSupervisor

  @type stream :: Tai.Venues.Stream.t()

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start(stream) :: DynamicSupervisor.on_start_child()
  def start(stream) do
    spec = {stream.venue.adapter.stream_supervisor, stream}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop(pid) when is_pid(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def which_children do
    DynamicSupervisor.which_children(__MODULE__)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
