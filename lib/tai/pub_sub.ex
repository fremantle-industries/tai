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
    Registry.start_link(:duplicate, __MODULE__, partitions: System.schedulers_online)
  end

  def subscribe(topic) do
    Registry.register(__MODULE__, topic, [])
  end

  def unsubscribe(topic) do
    Registry.unregister(__MODULE__, topic)
  end

  def broadcast(topic, message) do
    Registry.dispatch(__MODULE__, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end);
  end
end
