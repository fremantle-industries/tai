defmodule Tai.Advisors.Supervisor do
  use DynamicSupervisor

  def start_link(_), do: DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: DynamicSupervisor.init(strategy: :one_for_one)

  def start_advisor(spec), do: DynamicSupervisor.start_child(__MODULE__, spec)

  def terminate_advisor(pid) when is_pid(pid),
    do: DynamicSupervisor.terminate_child(__MODULE__, pid)
end
