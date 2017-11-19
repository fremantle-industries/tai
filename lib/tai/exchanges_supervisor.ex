defmodule Tai.ExchangesSupervisor do
  use Supervisor

  def start_link(_state) do
    Supervisor.start_link(__MODULE__, Tai.Settings.exchanges)
  end

  def init(exchanges) do
    exchanges
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(exchanges) do
    exchanges |> Enum.map(&config_to_child_spec/1)
  end

  defp config_to_child_spec({name, config}) do
    Supervisor.child_spec({Tai.Exchange, {name, config}}, id: name)
  end
end
