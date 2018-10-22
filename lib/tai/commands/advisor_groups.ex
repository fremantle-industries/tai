defmodule Tai.Commands.AdvisorGroups do
  require Logger

  @spec start :: no_return
  def start do
    children =
      Tai.AdvisorGroups.specs()
      |> Enum.map(&Tai.AdvisorsSupervisor.start_advisor/1)

    count = Enum.count(children)

    IO.puts("Started #{count} advisors")
  end

  @spec stop :: no_return
  def stop do
    started_advisors =
      Tai.AdvisorGroups.specs()
      |> Enum.map(fn {_, [group_id: gid, advisor_id: aid, order_books: _, store: _]} ->
        [group_id: gid, advisor_id: aid] |> Tai.Advisor.to_name() |> Process.whereis()
      end)
      |> Enum.filter(&(&1 != nil))
      |> Enum.map(&Tai.AdvisorsSupervisor.terminate_advisor/1)

    count = Enum.count(started_advisors)

    IO.puts("Stopped #{count} advisors")
  end
end
