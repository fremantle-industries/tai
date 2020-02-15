defmodule Tai.Application do
  use Application

  def start(_type, _args) do
    Confex.resolve_env!(:tai)

    config = Tai.Config.parse()

    children = [
      {Tai.PubSub, config.pub_sub_registry_partitions},
      {Tai.Events, config.event_registry_partitions},
      Tai.EventsLogger,
      {Tai.Settings, config},
      Tai.Trading.PositionStore,
      Tai.Trading.OrderStore,
      Tai.Markets.QuoteStore,
      Tai.Venues.ProductStore,
      Tai.Venues.FeeStore,
      Tai.Venues.AccountStore,
      Tai.Venues.StreamsSupervisor,
      {Task.Supervisor, name: Tai.TaskSupervisor, restart: :transient},
      Tai.Advisors.SpecStore,
      Tai.Advisors.Supervisor
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Tai.Supervisor)
  end

  def start_phase(:venues, _start_type, _phase_args) do
    config = Tai.Config.parse()

    config
    |> Tai.Venues.Config.parse()
    |> Enum.map(fn {_, venue} ->
      task =
        Task.Supervisor.async(
          Tai.TaskSupervisor,
          Tai.Venues.Boot,
          :run,
          [venue],
          timeout: venue.timeout
        )

      {task, venue}
    end)
    |> Enum.map(fn {task, venue} -> Task.await(task, venue.timeout) end)
    |> Enum.each(&config.venue_boot_handler.parse_response/1)

    :ok
  end

  def start_phase(:advisors, _start_type, _phase_args) do
    Tai.Config.parse()
    |> Tai.Advisors.Specs.from_config()
    |> Enum.map(&Tai.Advisors.SpecStore.put/1)
    |> Enum.map(fn {:ok, {_, spec}} -> spec end)
    |> Enum.map(&Tai.Advisors.Instance.from_spec/1)
    |> Enum.filter(fn instance -> instance.start_on_boot end)
    |> Tai.Advisors.Instances.start()

    :ok
  end
end
