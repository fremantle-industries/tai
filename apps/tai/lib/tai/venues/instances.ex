defmodule Tai.Venues.Instances do
  @type venue :: Tai.Venue.t()

  @spec find(venue) :: {:ok, pid} | {:error, :not_found}
  def find(venue) do
    venue.id
    |> Tai.Venues.Start.to_name()
    |> Process.whereis()
    |> case do
      nil -> {:error, :not_found}
      pid -> {:ok, pid}
    end
  end

  @spec find_stream(venue) :: {:ok, pid} | {:error, :not_found}
  def find_stream(venue) do
    Tai.Venues.StreamsSupervisor.which_children()
    |> Enum.find(fn {:undefined, _pid, :supervisor, [mod]} ->
      mod == venue.adapter.stream_supervisor
    end)
    |> case do
      nil -> {:error, :not_found}
      {:undefined, pid, _, _} -> {:ok, pid}
    end
  end

  @spec stop(venue) :: :ok | {:error, :already_stopped}
  def stop(venue) do
    with {:ok, stream_pid} <- find_stream(venue),
         {:ok, start_pid} <- find(venue) do
      :ok = Tai.Venues.StreamsSupervisor.stop(stream_pid)
      :ok = Tai.Venues.Supervisor.stop(start_pid)
      :ok
    else
      {:error, :not_found} ->
        {:error, :already_stopped}
    end
  end
end
