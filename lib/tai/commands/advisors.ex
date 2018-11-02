defmodule Tai.Commands.Advisors do
  alias TableRex.Table

  @type config :: Tai.Config.t()

  @spec advisors() :: no_return
  @spec advisors(config :: config) :: no_return
  def advisors(config \\ Tai.Config.parse()) do
    config
    |> Tai.AdvisorGroups.build_specs()
    |> format_rows
    |> render!
  end

  @spec start() :: no_return
  @spec start(config :: config) :: no_return
  def start(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end
  end

  @spec stop() :: no_return
  @spec stop(config :: config) :: no_return
  def stop(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end
  end

  @spec start_advisor(group_id :: atom, advisor_id :: atom) :: no_return
  @spec start_advisor(group_id :: atom, advisor_id :: atom, config :: config) :: no_return
  def start_advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_advisor(config, group_id, advisor_id) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end
  end

  @spec stop_advisor(group_id :: atom, advisor_id :: atom) :: no_return
  @spec stop_advisor(group_id :: atom, advisor_id :: atom, config :: config) :: no_return
  def stop_advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_advisor(config, group_id, advisor_id) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end
  end

  defp format_rows({:ok, specs}) do
    specs
    |> Tai.Advisors.info()
    |> Enum.map(fn {{_, opts}, pid} ->
      [
        opts |> Keyword.fetch!(:group_id),
        opts |> Keyword.fetch!(:advisor_id),
        opts |> Keyword.fetch!(:store) |> format_col,
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
