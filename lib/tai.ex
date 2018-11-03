defmodule Tai do
  use Application

  def start(_type, _args) do
    config = Tai.Config.parse()
    settings = Tai.Settings.from_config(config)

    children = [
      Tai.PubSub,
      {Tai.Events, config.event_registry_partitions},
      Tai.EventsLogger,
      {Tai.Settings, settings},
      Tai.Exchanges.ProductStore,
      Tai.Exchanges.FeeStore,
      Tai.Exchanges.AssetBalances,
      Tai.Trading.OrderStore,
      Tai.Exchanges.AdaptersSupervisor,
      Tai.Exchanges.OrderBookFeedsSupervisor,
      {Task.Supervisor, name: Tai.TaskSupervisor, restart: :transient},
      Tai.AdvisorsSupervisor
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one, name: Tai.Supervisor)
    config |> boot_exchanges!()
    {:ok, pid}
  end

  defp boot_exchanges!(config) do
    config
    |> Tai.Exchanges.Exchange.parse_adapters()
    |> Enum.map(fn adapter ->
      task =
        Task.Supervisor.async(
          Tai.TaskSupervisor,
          Tai.Exchanges.Boot,
          :run,
          [adapter]
        )

      {task, adapter}
    end)
    |> Enum.map(fn {task, adapter} -> Task.await(task, adapter.timeout) end)
    |> Enum.each(&config.exchange_boot_handler.parse_response/1)
  end
end
