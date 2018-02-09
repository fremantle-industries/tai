defmodule Support.Strategies.Info do
  use GenServer
  alias Tai.Strategy

  def start_link(strategy_id) do
    {:ok, started_at, _offset} = DateTime.from_iso8601("2010-01-13T14:21:06+00:00")

    GenServer.start_link(
      __MODULE__,
      {strategy_id, started_at},
      name: strategy_id |> Strategy.to_name
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:info, _from, {strategy_id, started_at}) do
    {:reply, started_at, {strategy_id, started_at}}
  end
end
