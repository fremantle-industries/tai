defmodule Tai.Commands.Advisors do
  alias TableRex.Table

  @type config :: Tai.Config.t()

  @spec advisors(config :: config) :: no_return
  def advisors(config \\ Tai.Config.parse()) do
    config
    |> Tai.AdvisorGroups.build_specs()
    |> format_rows
    |> render!
  end

  defp format_rows({:ok, specs}) do
    specs
    |> Enum.map(fn {_, [group_id: gid, advisor_id: aid, order_books: _, store: store]} ->
      pid = [group_id: gid, advisor_id: aid] |> Tai.Advisor.to_name() |> Process.whereis()

      [
        gid,
        aid,
        store |> format_col,
        pid |> format_status_col,
        pid |> format_col
      ]
    end)
  end

  def format_status_col(val) when is_pid(val), do: :running
  def format_status_col(_), do: :unstarted

  defp format_col(val) when is_pid(val) or is_map(val), do: val |> inspect()
  defp format_col(nil), do: "-"
  defp format_col(val), do: val

  @header ["Group ID", "Advisor ID", "Store", "Status", "PID"]
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
