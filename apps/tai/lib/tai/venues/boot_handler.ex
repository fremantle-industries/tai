defmodule Tai.Venues.BootHandler do
  @type venue :: Tai.Venue.t()
  @type error_reason :: term

  @spec parse_response({:ok, venue} | {:error, {venue, error_reason}}) :: no_return
  def parse_response({:ok, venue}) do
    TaiEvents.info(%Tai.Events.VenueBoot{
      venue: venue.id
    })
  end

  def parse_response({:error, {venue, reason}}) do
    TaiEvents.error(%Tai.Events.VenueBootError{
      venue: venue.id,
      reason: reason
    })
  end
end
