defmodule Tai.Advisors.Supervisor do
  use DynamicSupervisor

  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()
  @type advisor_instance :: Tai.Advisors.Instance.t()

  @spec start_link(term) :: Supervisor.on_start()
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec start_advisor(advisor_config) :: DynamicSupervisor.on_start_child()
  def start_advisor(advisor_config) do
    # TODO: Need the ability to set the instance supervisor on advisors
    instance_supervisor = advisor_config.instance_supervisor || Tai.Advisors.InstanceSupervisor
    # TODO: Is this really the correct name?
    name = :"#{instance_supervisor}_#{advisor_config.fleet_id}_#{advisor_config.advisor_id}"
    spec = %{
      id: name,
      start: {instance_supervisor, :start_link, [advisor_config]},
      restart: advisor_config.restart,
      shutdown: advisor_config.shutdown,
      type: :supervisor
    }
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @spec terminate_advisor(pid) :: :ok | {:error, :not_found}
  def terminate_advisor(pid) when is_pid(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
