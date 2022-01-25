defmodule Support.StartStreamSupervisor do
  use Supervisor

  def start_link(stream) do
    name = process_name(stream.venue.id)
    Supervisor.start_link(__MODULE__, stream, name: name)
  end

  def process_name(venue), do: :"#{__MODULE__}_#{venue}"

  def init(_) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
