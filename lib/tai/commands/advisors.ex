defmodule Tai.Commands.Advisors do
  import Tai.Commands.Table, only: [render!: 2]

  @type config :: Tai.Config.t()

  @header [
    "Group ID",
    "Advisor ID",
    "Status",
    "PID"
  ]

  @spec advisors() :: no_return
  @spec advisors(config) :: no_return
  def advisors(config \\ Tai.Config.parse()) do
    config
    |> Tai.AdvisorGroups.build_specs()
    |> format_rows
    |> render!(@header)
  end

  @spec start() :: no_return
  @spec start(config :: config) :: no_return
  def start(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end

    IEx.dont_display_result()
  end

  @spec stop() :: no_return
  @spec stop(config) :: no_return
  def stop(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end

    IEx.dont_display_result()
  end

  defp format_rows({:ok, specs}) do
    specs
    |> Tai.Advisors.info()
    |> Enum.map(fn {{_, opts}, pid} ->
      [
        opts |> Keyword.fetch!(:group_id),
        opts |> Keyword.fetch!(:advisor_id),
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
end
