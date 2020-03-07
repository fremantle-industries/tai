defmodule Support.StartStreamSupervisor do
  use Supervisor

  def start_link(stream) do
    name = stream.venue.id |> to_name()
    Supervisor.start_link(__MODULE__, stream, name: name)
  end

  def init(_) do
    []
    |> Supervisor.init(strategy: :one_for_one)
  end

  def to_name(venue), do: :"#{__MODULE__}_#{venue}"
end
