defmodule Tai.Exchanges.AccountsSupervisor do
  use Supervisor

  alias Tai.Exchanges

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Exchanges.Config.account_supervisors()
    |> Enum.map(&account_child/1)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp account_child({account_id, supervisor}) do
    Supervisor.child_spec(
      {supervisor, account_id},
      id: "#{supervisor}_#{account_id}"
    )
  end
end
