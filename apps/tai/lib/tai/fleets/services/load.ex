defmodule Tai.Fleets.Services.Load do
  alias Tai.Fleets

  @type result :: {:ok, {loaded_fleets :: non_neg_integer, loaded_advisors :: non_neg_integer}}

  @spec execute(map) :: result
  def execute(config) do
    loaded = config
             |> build_configs()
             |> load_configs()

    {:ok, loaded}
  end

  defp build_configs(config) do
    config
    |> Enum.reduce(
      [],
      fn {fleet_id, attrs}, acc ->
        fleet_config = build_fleet_config(fleet_id, attrs)
        advisor_configs = build_advisor_configs(fleet_config)
        [{fleet_config, advisor_configs} | acc]
      end
    )
  end

  defp load_configs(fleet_and_advisor_configs) do
    fleet_and_advisor_configs
    |> Enum.reduce(
      {0, 0},
      fn {fleet_config, advisor_configs}, {loaded_fleets, loaded_advisors} ->
        {:ok, _} = Fleets.FleetConfigStore.put(fleet_config)
        new_advisors = advisor_configs
                       |> Enum.reduce(
                         0,
                         fn advisor_config, acc ->
                           {:ok, _} = Fleets.AdvisorConfigStore.put(advisor_config)
                           acc+1
                         end
                       )

        {loaded_fleets+1, loaded_advisors+new_advisors}
      end
    )
  end

  defp build_fleet_config(fleet_id, attrs) do
    factory = fetch!(attrs, :factory)
    advisor = fetch!(attrs, :advisor)
    market_streams = get(attrs, :market_streams)
    start_on_boot = get(attrs, :start_on_boot)
    restart = get(attrs, :restart)
    shutdown = get(attrs, :shutdown)
    config = get(attrs, :config)

    %Fleets.FleetConfig{
      id: fleet_id,
      factory: factory,
      advisor: advisor,
      market_streams: market_streams,
      start_on_boot: start_on_boot,
      restart: restart,
      shutdown: shutdown,
      config: config
    }
  end

  defp build_advisor_configs(fleet_config) do
    fleet_config.factory.advisor_configs(fleet_config)
  end

  defp fetch!(attrs, key), do: Map.fetch!(attrs, key)

  defp get(attrs, :start_on_boot = key), do: Map.get(attrs, key, false)
  defp get(attrs, :restart = key), do: Map.get(attrs, key, :temporary)
  defp get(attrs, :shutdown = key), do: Map.get(attrs, key, 5_000)
  defp get(attrs, :market_streams = key), do: Map.get(attrs, key, "")
  defp get(attrs, :config = key) do
    case Map.get(attrs, key, %{}) do
      {s, c} -> struct!(s, c |> Tai.Advisors.Groups.RichConfig.parse())
      c -> c |> Tai.Advisors.Groups.RichConfig.parse()
    end
  end
end
