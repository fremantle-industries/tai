defmodule Tai do
  use Application

  def start(_type, _args) do
    settings_config = Tai.SettingsConfig.parse()

    children = [
      Tai.PubSub,
      {Tai.Settings, settings_config},
      Tai.Exchanges.ProductStore,
      Tai.Exchanges.FeeStore,
      Tai.Exchanges.AssetBalances,
      Tai.Trading.OrderStore,
      Tai.AdvisorsSupervisor,
      Tai.Exchanges.AdaptersSupervisor,
      {Task.Supervisor, name: Tai.TaskSupervisor, restart: :transient},
      # TODO
      # OrderBookFeedsSupervisor will become the responsibility of each 
      # individual adapter supervisor. Once complete it can be removed.
      Tai.Exchanges.OrderBookFeedsSupervisor
    ]

    {:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one, name: Tai.Supervisor)
    boot_exchanges!(&settings_config.exchange_boot_handler.parse_response/1)
    {:ok, pid}
  end

  defp boot_exchanges!(response_handler) do
    :tai
    |> Application.get_env(:venues)
    |> Tai.Exchanges.Exchange.parse_configs()
    |> Enum.map(fn adapter ->
      Task.Supervisor.async(
        Tai.TaskSupervisor,
        Tai.Exchanges.Boot,
        :run,
        [adapter]
      )
    end)
    |> Enum.map(&Task.await/1)
    |> Enum.each(response_handler)
  end
end
