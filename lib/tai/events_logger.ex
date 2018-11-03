defmodule Tai.EventsLogger do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    Tai.Events.firehose_subscribe()
    {:ok, state}
  end

  def handle_info({Tai.Event, event}, state) do
    event
    |> Tai.Event.encode!()
    |> Logger.info(tid: __MODULE__)

    {:noreply, state}
  end
end
