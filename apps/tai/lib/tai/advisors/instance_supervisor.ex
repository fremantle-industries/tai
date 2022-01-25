defmodule Tai.Advisors.InstanceSupervisor do
  use Supervisor

  @moduledoc """
  The default supervisor for advisor instances. This supervisor can be replaced
  with a custom implementation by setting `Tai.Fleets.AdvisorConfig#instance_supervisor`.
  """

  @type advisor_config :: Tai.Fleets.AdvisorConfig.t()

  @spec start_link(advisor_config) :: Supervisor.on_start()
  def start_link(advisor_config) do
    name = process_name(advisor_config)
    Supervisor.start_link(__MODULE__, advisor_config, name: name)
  end

  @spec process_name(advisor_config) :: atom
  def process_name(advisor_config) do
    :"#{__MODULE__}_#{advisor_config.fleet_id}_#{advisor_config.advisor_id}"
  end

  @spec advisor_child_spec(advisor_config) :: Supervisor.child_spec()
  def advisor_child_spec(advisor_config) do
    name = Tai.Advisor.process_name(advisor_config.fleet_id, advisor_config.advisor_id)
    start_args = [
      advisor_id: advisor_config.advisor_id,
      fleet_id: advisor_config.fleet_id,
      market_stream_keys: advisor_config.market_stream_keys,
      config: advisor_config.config,
      store: %{}
    ]

    %{
      id: name,
      start: {advisor_config.mod, :start_link, [start_args]},
      type: :worker
    }
  end

  @impl true
  def init(advisor_config) do
    advisor_spec = advisor_child_spec(advisor_config)
    children = [advisor_spec]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
