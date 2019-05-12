defmodule Tai.Commands.Advisor do
  @type group_id :: Tai.AdvisorGroup.id()
  @type advisor_id :: Tai.Advisor.id()
  @type config :: Tai.Config.t()

  @spec advisor(group_id, advisor_id, config) :: no_return
  def advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    config
    |> Tai.Advisors.specs(group_id: group_id, advisor_id: advisor_id)
    |> case do
      [_ | _] = specs ->
        [{{_, opts}, pid} | []] = specs |> Tai.Advisors.info()
        IO.puts("Group ID: #{opts |> Keyword.fetch!(:group_id)}")
        IO.puts("Advisor ID: #{opts |> Keyword.fetch!(:advisor_id)}")
        IO.puts("Status: #{pid |> format_status_col}")
        IO.puts("PID: #{pid |> format_col}")
        IO.puts("Config: #{opts |> Keyword.fetch!(:config) |> format_col}")

      _ ->
        IO.puts("Group ID: -")
        IO.puts("Advisor ID: -")
        IO.puts("Status: -")
        IO.puts("PID: -")
        IO.puts("Config: -")
    end

    IEx.dont_display_result()
  end

  @spec start_advisor(group_id, advisor_id, config) :: no_return
  def start_advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    {:ok, {new, old}} =
      config
      |> Tai.Advisors.specs(group_id: group_id, advisor_id: advisor_id)
      |> Tai.Advisors.start()

    IO.puts("Started advisors: #{new} new, #{old} already running")
    IEx.dont_display_result()
  end

  @spec stop_advisor(group_id, advisor_id, config) :: no_return
  def stop_advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    {:ok, {new, old}} =
      config
      |> Tai.Advisors.specs(group_id: group_id, advisor_id: advisor_id)
      |> Tai.Advisors.stop()

    IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    IEx.dont_display_result()
  end

  def format_status_col(val) when is_pid(val), do: :running
  def format_status_col(_), do: :unstarted

  defp format_col(val) when is_pid(val) or is_map(val), do: val |> inspect()
  defp format_col(nil), do: "-"
  defp format_col(val), do: val
end
