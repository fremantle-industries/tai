defmodule Tai.Advisors.Supervisor do
  use Supervisor

  alias Tai.Advisors.Config

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Config.all()
    |> Enum.map(fn %{id: id, supervisor: supervisor} ->
      %{
        id: id,
        start: {supervisor, :start_link, [[id: id]]},
        type: :supervisor
      }
    end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
