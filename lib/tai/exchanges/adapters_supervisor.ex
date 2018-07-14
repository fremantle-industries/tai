defmodule Tai.Exchanges.AdaptersSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  def init(:ok) do
    Tai.Exchanges.Config.all()
    |> Enum.map(fn %Tai.Exchanges.Config{} = config ->
      {config.supervisor, config}
      |> Supervisor.child_spec(id: config.id)
    end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
