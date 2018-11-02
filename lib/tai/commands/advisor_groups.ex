defmodule Tai.Commands.AdvisorGroups do
  alias TableRex.Table

  @type config :: Tai.Config.t()

  @spec advisor_groups(config :: config) :: no_return
  def advisor_groups(config \\ Tai.Config.parse()) do
    config
    |> Tai.AdvisorGroups.build_specs()
    |> agg_status_by_group
    |> format_rows
    |> render!
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

  @header ["Group ID", "Running", "Unstarted", "Total"]
  @spec render!(rows :: [...]) :: no_return
  defp render!(rows)

  defp render!([]) do
    col_count = @header |> Enum.count()

    [List.duplicate("-", col_count)]
    |> render!
  end

  defp render!(rows) do
    rows
    |> Table.new(@header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
