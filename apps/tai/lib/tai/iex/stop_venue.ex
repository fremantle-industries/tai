defmodule Tai.IEx.Commands.StopVenue do
  @type venue_id :: Tai.Venue.id()
  @type store_id :: Tai.Venues.VenueStore.store_id()
  @type options :: Tai.Commander.StopVenue.options()

  @spec stop(venue_id, options) :: no_return
  def stop(venue_id, options) do
    venue_id
    |> Tai.Commander.StopVenue.execute(options)
    |> case do
      :ok ->
        IO.puts("stopped successfully")

      {:error, :already_stopped} ->
        IO.puts("error: #{inspect(venue_id)} is already stopped")

      {:error, :not_found} ->
        IO.puts("error: #{inspect(venue_id)} was not found")
    end

    IEx.dont_display_result()
  end
end
