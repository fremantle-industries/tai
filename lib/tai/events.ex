defmodule Tai.Events do
  @type event :: Tai.Event.t()

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

  @spec start_link(partitions :: pos_integer) :: {:ok, pid} | {:error, term}
  def start_link(partitions) when partitions > 0 do
    Registry.start_link(keys: :duplicate, name: __MODULE__, partitions: partitions)
  end

  @spec firehose_subscribe ::
          {:ok, pid}
          | {:error, {:already_registered, pid} | :event_not_registered}
  def firehose_subscribe do
    Registry.register(__MODULE__, :firehose, [])
  end

  @spec subscribe(event_type :: atom) ::
          {:ok, pid}
          | {:error, {:already_registered, pid} | :event_not_registered}
  def subscribe(event_type) when is_atom(event_type) do
    Registry.register(__MODULE__, event_type, [])
  end

  @spec broadcast(event) :: :ok
  def broadcast(event) do
    event_type = Map.fetch!(event, :__struct__)
    msg = {Tai.Event, event}

    Registry.dispatch(__MODULE__, event_type, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)

    Registry.dispatch(__MODULE__, :firehose, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)

    :ok
  end
end
