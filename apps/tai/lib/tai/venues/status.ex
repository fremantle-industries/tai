defmodule Tai.Venues.Status do
  @type venue :: Tai.Venue.t()

  @spec status(venue) :: :stopped | :starting | :running | :error
  def status(venue) do
    venue
    |> find_stream
    |> check_stream
    |> check_instance
  end

  defp find_stream(venue) do
    result = Tai.Venues.Instances.find_stream(venue)
    {result, venue}
  end

  defp check_stream({{:ok, pid}, _venue}) when is_pid(pid) do
    :running
  end

  defp check_stream({{:error, :not_found}, venue}) do
    result = Tai.Venues.Instances.find(venue)
    {result, venue}
  end

  defp check_instance(:running), do: :running
  defp check_instance({{:error, :not_found}, _venue}), do: :stopped

  defp check_instance({{:ok, _pid}, venue}) do
    venue.id
    |> Tai.Venues.Start.status()
    |> case do
      {:error, _} -> :error
      _ -> :starting
    end
  end
end
