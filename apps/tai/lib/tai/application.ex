defmodule Tai.Application do
  use Application

  def start(_type, _args) do
    Confex.resolve_env!(:tai)

    config = Tai.Config.parse()
    settings = Tai.Settings.from_config(config)

    children = [
      {Tai.PubSub, config.pub_sub_registry_partitions},
      {Tai.Events, config.event_registry_partitions},
      Tai.EventsLogger,
      {Tai.Settings, settings},
      Tai.Trading.PositionStore,
      Tai.Trading.OrderStore,
      Tai.Markets.QuoteStore,
      Tai.Venues.ProductStore,
      Tai.Venues.FeeStore,
      Tai.Venues.AssetBalanceStore,
      Tai.Venues.StreamsSupervisor,
      {Task.Supervisor, name: Tai.TaskSupervisor, restart: :transient},
      Tai.Advisors.Store,
      Tai.Advisors.Supervisor
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one, name: Tai.Supervisor)

    config
    |> boot_venues!()
    |> hydrate_advisors!()
    |> boot_advisors!()

    {:ok, pid}
  end

  defp boot_venues!(config) do
    config
    |> Tai.Venues.Config.parse_adapters()
    |> Enum.map(fn {_, adapter} ->
      task =
        Task.Supervisor.async(
          Tai.TaskSupervisor,
          Tai.Venues.Boot,
          :run,
          [adapter],
          timeout: adapter.timeout
        )

      {task, adapter}
    end)
    |> Enum.map(fn {task, adapter} -> Task.await(task, adapter.timeout) end)
    |> Enum.each(&config.venue_boot_handler.parse_response/1)

    {:ok, config}
  end

  defp hydrate_advisors!({:ok, config}) do
    config
    |> Tai.Advisors.Specs.from_config()
    |> Enum.map(&Tai.Advisors.Instance.from_spec/1)
    |> Enum.map(&Tai.Advisors.Store.upsert/1)
  end

  defp boot_advisors!(upsert_results) do
    upsert_results
    |> Enum.map(fn {:ok, instance} -> instance end)
    |> Enum.filter(fn instance -> instance.start_on_boot end)
    |> Tai.Advisors.Instances.start()
  end
end
