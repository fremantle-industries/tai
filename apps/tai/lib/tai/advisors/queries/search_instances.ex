defmodule Tai.Advisors.Queries.SearchInstances do
  alias Tai.Advisors

  @type result :: [Advisors.Instance.t()]

  @spec call(term) :: result
  def call(query) do
    query
    |> Advisors.Queries.SearchConfigs.call()
    |> Enum.map(fn c ->
      pid = whereis(c)
      status = to_status(pid)

      %Advisors.Instance{
        advisor_id: c.advisor_id,
        fleet_id: c.fleet_id,
        start_on_boot: c.start_on_boot,
        restart: c.restart,
        shutdown: c.shutdown,
        config: c.config,
        pid: pid,
        status: status,
      }
    end)
  end

  defp whereis(advisor_config) do
    advisor_config
    |> Advisors.InstanceSupervisor.process_name()
    |> Process.whereis()
  end

  defp to_status(pid) do
    case pid do
      pid when is_pid(pid) -> :running
      _ -> :unstarted
    end
  end
end
