defmodule Tai.AccountsSupervisor do
  use Supervisor

  def start_link(_state) do
    Supervisor.start_link(__MODULE__, Tai.Settings.accounts)
  end

  def init(accounts) do
    accounts
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(accounts) do
    accounts |> Enum.map(&config_to_child_spec/1)
  end

  defp config_to_child_spec({name, config}) do
    Supervisor.child_spec({Tai.Account, {name, config}}, id: name)
  end
end
