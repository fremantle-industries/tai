defmodule Tai.Strategies.Info do
  use GenServer
  alias Tai.Strategy

  def start_link(name) do
    {:ok, started_at, _offset} = DateTime.from_iso8601("2010-01-13T14:21:06+00:00")

    name
    |> Strategy.to_pid
    |> (&GenServer.start_link(
      __MODULE__,
      {name, started_at},
      name: &1
    )).()
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:info, _from, {name, started_at}) do
    {:reply, started_at, {name, started_at}}
  end
end
