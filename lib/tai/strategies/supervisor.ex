defmodule Tai.Strategies.Supervisor do
  use Supervisor
  alias Tai.Strategies.Config
  alias Tai.Strategy

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Config.all
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(strategies) do
    strategies
    |> Enum.map(&config_to_child_spec/1)
  end

  defp config_to_child_spec({strategy_id, strategy}) do
    Supervisor.child_spec({strategy, strategy_id}, id: strategy_id |> Strategy.to_name)
  end
end
