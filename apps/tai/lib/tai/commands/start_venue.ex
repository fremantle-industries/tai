defmodule Tai.Commands.StartVenue do
  @type venue_id :: Tai.Venue.id()
  @type store_id :: Tai.Venues.VenueStore.store_id()

  @spec start(venue_id, store_id) :: no_return
  def start(venue_id, store_id \\ Tai.Venues.VenueStore.default_store_id()) do
    {venue_id, store_id}
    |> find_venue
    |> start_venue

    IEx.dont_display_result()
  end

  defp find_venue({venue_id, store_id}) do
    result = Tai.Venues.VenueStore.find(venue_id, store_id)
    {result, venue_id, store_id}
  end

  defp start_venue({{:ok, venue}, _venue_id, _store_id}) do
    venue
    |> Tai.Venues.Supervisor.start()
    |> case do
      {:ok, _} ->
        IO.puts("starting...")

      {:error, {:already_started, _}} ->
        IO.puts("error: #{inspect(venue.id)} is already started")
    end
  end

  defp start_venue({{:error, :not_found}, venue_id, _store_id}) do
    IO.puts("error: #{inspect(venue_id)} was not found")
  end
end
