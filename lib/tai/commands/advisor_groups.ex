defmodule Tai.Commands.AdvisorGroups do
  @type config :: Tai.Config.t()

  @spec start(config :: config) :: no_return
  def start(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end
  end

  @spec stop(config :: config) :: no_return
  def stop(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end
  end

  @spec start_group(group_id :: atom, config :: config) :: no_return
  def start_group(group_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_group(config, group_id) do
      {:ok, {new, old}} = Tai.Advisors.start(specs)
      IO.puts("Started advisors: #{new} new, #{old} already running")
    end
  end

  @spec stop_group(group_id :: atom, config :: config) :: no_return
  def stop_group(group_id, config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs_for_group(config, group_id) do
      {:ok, {new, old}} = Tai.Advisors.stop(specs)
      IO.puts("Stopped advisors: #{new} new, #{old} already stopped")
    end
  end
end
