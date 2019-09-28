defmodule Tai.PubSub do
  @type partitions :: pos_integer

  @spec child_spec(opts :: term) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  @spec start_link(partitions) :: {:ok, pid} | {:error, term}
  def start_link(partitions) do
    Registry.start_link(
      keys: :duplicate,
      name: __MODULE__,
      partitions: partitions
    )
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
