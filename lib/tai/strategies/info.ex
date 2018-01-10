defmodule Tai.Strategies.Info do
  use GenServer
  alias Tai.Strategy

  def start_link(name) do
    {:ok, started_at, _offset} = DateTime.from_iso8601("2010-01-13T14:21:06+00:00")

    GenServer.start_link(
      __MODULE__,
      {name, started_at},
      name: name |> Strategy.to_pid
    )
  end

  def init(name) do
    {:ok, name}
  end

  def handle_call(:info, _from, {name, started_at}) do
    {:reply, started_at, {name, started_at}}
  end
end
