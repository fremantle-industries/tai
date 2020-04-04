defmodule Tai.IEx.Commands.StopVenue do
  @type venue_id :: Tai.Venue.id()
  @type store_id :: Tai.Venues.VenueStore.store_id()

  @spec stop(venue_id, store_id) :: no_return
  def stop(venue_id, store_id \\ Tai.Venues.VenueStore.default_store_id()) do
    {venue_id, store_id}
    |> find_venue
    |> stop_instance

    IEx.dont_display_result()
  end

  defp find_venue({venue_id, store_id}) do
    result = Tai.Venues.VenueStore.find(venue_id, store_id)
    {result, venue_id}
  end

  defp stop_instance({{:ok, venue}, _venue_id}) do
    venue
    |> Tai.Venues.Instance.stop()
    |> case do
      :ok ->
        IO.puts("stopped successfully")

      {:error, :already_stopped} ->
        IO.puts("error: #{inspect(venue.id)} is already stopped")
    end
  end

  defp stop_instance({{:error, :not_found}, venue_id}) do
    IO.puts("error: #{inspect(venue_id)} was not found")
  end
end
