defmodule Tai.Strategies.Supervisor do
  use Supervisor
  alias Tai.Strategies.Config

  def start_link(_state) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    Config.all
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(strategies) do
    strategies
    |> Enum.map(&config_to_child_spec/1)
  end

  defp config_to_child_spec({name, strategy}) do
    Supervisor.child_spec({strategy, name}, id: name)
  end
end
