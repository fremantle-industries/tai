defmodule Tai.Events do
  @type event :: Tai.Event.t()
  @type level :: :debug | :info | :warn | :error

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

  @spec error(event) :: :ok
  def error(event), do: event |> broadcast(:error)
  @spec warn(event) :: :ok
  def warn(event), do: event |> broadcast(:warn)
  @spec info(event) :: :ok
  def info(event), do: event |> broadcast(:info)
  @spec debug(event) :: :ok
  def debug(event), do: event |> broadcast(:debug)

  @deprecated "Use Tai.Events.info/1 instead."
  @spec broadcast(event) :: :ok
  def broadcast(event), do: event |> info()

  @spec broadcast(event, level) :: :ok
  def broadcast(event, level) do
    event_type = Map.fetch!(event, :__struct__)
    msg = {Tai.Event, event, level}

    Registry.dispatch(__MODULE__, event_type, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)

    Registry.dispatch(__MODULE__, :firehose, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)

    :ok
  end
end
