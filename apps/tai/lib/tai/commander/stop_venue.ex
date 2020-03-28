defmodule Tai.Commander.StopVenue do
  @type venue_id :: Tai.Venue.id()
  @type opt :: {:store_id, Tai.Venues.VenueStore.store_id()}
  @type options :: [opt]
  @type error_reasons :: :already_stopped | :not_found

  @default_store_id Tai.Venues.VenueStore.default_store_id()

  @spec execute(venue_id, options) :: :ok | {:error, error_reasons}
  def execute(venue_id, options) do
    store_id = Keyword.get(options, :store_id, @default_store_id)

    {venue_id, store_id}
    |> find_venue
    |> stop_instance
  end

  defp find_venue({venue_id, store_id}) do
    Tai.Venues.VenueStore.find(venue_id, store_id)
  end

  defp stop_instance({:ok, venue}), do: Tai.Venues.Instances.stop(venue)
  defp stop_instance({:error, :not_found} = error), do: error
end
