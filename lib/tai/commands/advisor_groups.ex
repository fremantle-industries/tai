defmodule Tai.Commands.AdvisorGroups do
  @type config :: Tai.Config.t()

  @spec start(config :: config) :: no_return
  def start(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      children = Enum.map(specs, &Tai.AdvisorsSupervisor.start_advisor/1)
      count = Enum.count(children)
      IO.puts("Started #{count} advisors")
    end
  end

  @spec stop(config :: config) :: no_return
  def stop(config \\ Tai.Config.parse()) do
    with {:ok, specs} <- Tai.AdvisorGroups.build_specs(config) do
      started_advisors =
        specs
        |> Tai.AdvisorGroups.info()
        |> Enum.map(fn {_, pid} -> pid end)
        |> Enum.filter(&(&1 != nil))
        |> Enum.map(&Tai.AdvisorsSupervisor.terminate_advisor/1)

      count = Enum.count(started_advisors)
      IO.puts("Stopped #{count} advisors")
    end
  end
end
