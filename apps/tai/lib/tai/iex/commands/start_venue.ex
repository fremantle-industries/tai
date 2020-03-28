defmodule Tai.IEx.Commands.StartVenue do
  @type venue_id :: Tai.Venue.id()
  @type store_id :: Tai.Venues.VenueStore.store_id()
  @type options :: Tai.Commander.StartVenue.options()

  @spec start(venue_id, options) :: no_return
  def start(venue_id, options \\ []) do
    venue_id
    |> Tai.Commander.StartVenue.execute(options)
    |> case do
      {:ok, _} ->
        IO.puts("starting...")

      {:error, {:already_started, _}} ->
        IO.puts("error: #{inspect(venue_id)} is already started")

      {:error, :not_found} ->
        IO.puts("error: #{inspect(venue_id)} was not found")
    end

    IEx.dont_display_result()
  end
end
