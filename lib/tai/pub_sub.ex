defmodule Tai.PubSub do
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_) do
    Registry.start_link(:duplicate, __MODULE__, partitions: System.schedulers_online())
  end

  def subscribe([]), do: :ok

  def subscribe([topic | tail]) do
    Registry.register(__MODULE__, topic, [])
    subscribe(tail)
  end

  def subscribe(topic) do
    topic
    |> List.wrap()
    |> subscribe
  end

  def unsubscribe([]), do: :ok

  def unsubscribe([topic | tail]) do
    Registry.unregister(__MODULE__, topic)
    unsubscribe(tail)
  end

  def unsubscribe(topic) do
    topic
    |> List.wrap()
    |> unsubscribe
  end

  def broadcast(topic, message) do
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
  end
end
