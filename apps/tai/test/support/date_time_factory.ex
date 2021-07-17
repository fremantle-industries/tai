defmodule Support.DateTimeFactory do
  use Agent

  @date_times [
    DateTime.from_naive!(~N[2016-05-24 13:00:00.000000], "Etc/UTC"),
    DateTime.from_naive!(~N[2017-08-02 08:22:00.999000], "Etc/UTC")
  ]

  def start_link(_) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def utc_now() do
    call_count = Agent.get_and_update(__MODULE__, fn c -> {c, c + 1} end)
    Enum.at(@date_times, call_count)
  end
end
