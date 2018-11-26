defmodule Tai.Commands.AdvisorGroups do
  import Tai.Commands.Table, only: [render!: 2]

  @type config :: Tai.Config.t()

  @header [
    "Group ID",
    "Running",
    "Unstarted",
    "Total"
  ]

  @spec advisor_groups() :: no_return
  @spec advisor_groups(config :: config) :: no_return
  def advisor_groups(config \\ Tai.Config.parse()) do
    config
    |> Tai.AdvisorGroups.build_specs()
    |> agg_status_by_group
    |> format_rows
    |> render!(@header)
  end

  @spec start(group_id :: atom) :: no_return
  @spec start(group_id :: atom, config :: config) :: no_return
  def start(group_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_group(config, group_id) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end

    IEx.dont_display_result()
  end

  @spec stop(group_id :: atom) :: no_return
  @spec stop(group_id :: atom, config :: config) :: no_return
  def stop(group_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_group(config, group_id) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end

    IEx.dont_display_result()
  end

  defp agg_status_by_group({:ok, specs}) do
    specs
    |> Tai.Advisors.info()
    |> Enum.map(fn {{_, opts}, pid} -> {Keyword.fetch!(opts, :group_id), pid} end)
    |> Enum.reduce(
      %{},
      fn {group_id, pid}, acc ->
        {_, _} = counts = Map.get(acc, group_id, {0, 0})
        counts = counts |> increment(pid)
        Map.put(acc, group_id, counts)
      end
    )
  end

  defp increment({running, unstarted}, pid) when is_pid(pid), do: {running + 1, unstarted}
  defp increment({running, unstarted}, _), do: {running, unstarted + 1}

  defp format_rows(status_by_group) do
    status_by_group
    |> Enum.map(fn {group_id, {running, unstarted}} ->
      [group_id, running, unstarted, running + unstarted]
    end)
    |> Enum.sort(fn [group_a, _, _, _], [group_b, _, _, _] ->
      group_a > group_b
    end)
  end
end
