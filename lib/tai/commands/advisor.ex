defmodule Tai.Commands.Advisor do
  @type config :: Tai.Config.t()

  @spec advisor(atom, atom) :: no_return
  @spec advisor(atom, atom, config) :: no_return
  def advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    with {:ok, [spec | _]} <-
           Tai.AdvisorGroups.build_specs_for_advisor(config, group_id, advisor_id) do
      [spec]
      |> Tai.Advisors.info()
      |> Enum.each(fn {{_, opts}, pid} ->
        IO.puts("Group ID: #{opts |> Keyword.fetch!(:group_id)}")
        IO.puts("Advisor ID: #{opts |> Keyword.fetch!(:advisor_id)}")
        IO.puts("Config: #{opts |> Keyword.fetch!(:config) |> format_col}")
        IO.puts("Status: #{pid |> format_status_col}")
        IO.puts("PID: #{pid |> format_col}")
      end)
    else
      {:ok, []} ->
        IO.puts("Group ID: -")
        IO.puts("Advisor ID: -")
        IO.puts("Config: -")
        IO.puts("Status: -")
        IO.puts("PID: -")
    end

    IEx.dont_display_result()
  end

  @spec start_advisor(atom, atom) :: no_return
  @spec start_advisor(atom, atom, config) :: no_return
  def start_advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_advisor(config, group_id, advisor_id) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end

    IEx.dont_display_result()
  end

  @spec stop_advisor(atom, atom) :: no_return
  @spec stop_advisor(atom, atom, config) :: no_return
  def stop_advisor(group_id, advisor_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_advisor(config, group_id, advisor_id) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end

    IEx.dont_display_result()
  end

  def format_status_col(val) when is_pid(val), do: :running
  def format_status_col(_), do: :unstarted

  defp format_col(val) when is_pid(val) or is_map(val), do: val |> inspect()
  defp format_col(nil), do: "-"
  defp format_col(val), do: val
end
