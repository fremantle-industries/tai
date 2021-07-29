defmodule Tai.VenueAdapters.Stub.StreamSupervisor do
  use Supervisor

  @spec start_link(Tai.Venues.Stream.t()) :: Supervisor.on_start()
  def start_link(stream) do
    name = process_name(stream.venue.id)
    Supervisor.start_link(__MODULE__, stream, name: name)
  end

  @spec process_name(Tai.Venue.id()) :: atom
  def process_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(_stream) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
