defmodule Support.StartStreamSupervisor do
  use Supervisor

  def start_link(venue: venue, products: _, accounts: _) do
    name = venue.id |> to_name()
    Supervisor.start_link(__MODULE__, :ok, name: name)
  end

  def init(_) do
    []
    |> Supervisor.init(strategy: :one_for_one)
  end

  def to_name(venue), do: :"#{__MODULE__}_#{venue}"
end
