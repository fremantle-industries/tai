defmodule TaiEvents do
  @type event :: TaiEvents.Event.t()
  @type event_type :: module
  @type partitions :: pos_integer
  @type level :: :debug | :info | :warning | :error
  @type subscribe_error_reasons :: {:already_registered, pid} | :event_not_registered

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
  def start_link(partitions) when partitions > 0 do
    Registry.start_link(keys: :duplicate, name: __MODULE__, partitions: partitions)
  end

  @spec firehose_subscribe :: {:ok, pid} | {:error, subscribe_error_reasons}
  def firehose_subscribe do
    Registry.register(__MODULE__, :firehose, [])
  end

  @spec subscribe(event_type) :: {:ok, pid} | {:error, :subscribe_error_reasons}
  def subscribe(event_type) when is_atom(event_type) do
    Registry.register(__MODULE__, event_type, [])
  end

  @spec error(event) :: :ok
  def error(event), do: event |> broadcast(:error)
  @spec warning(event) :: :ok
  def warning(event), do: event |> broadcast(:warning)
  @spec info(event) :: :ok
  def info(event), do: event |> broadcast(:info)
  @spec debug(event) :: :ok
  def debug(event), do: event |> broadcast(:debug)

  @spec broadcast(event, level) :: :ok
  def broadcast(event, level) do
    event_type = Map.fetch!(event, :__struct__)
    msg = {TaiEvents.Event, event, level}

    Registry.dispatch(__MODULE__, event_type, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)

    Registry.dispatch(__MODULE__, :firehose, fn entries ->
      for {pid, _} <- entries, do: send(pid, msg)
    end)

    :ok
  end
end
