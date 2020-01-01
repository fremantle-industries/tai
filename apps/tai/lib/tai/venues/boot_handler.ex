defmodule Tai.Venues.BootHandler do
  alias Tai.Events

  @type venue :: Tai.Venue.t()
  @type error_reason :: term

  @spec parse_response({:ok, venue} | {:error, {venue, error_reason}}) :: no_return
  def parse_response({:ok, venue}) do
    Events.info(%Events.VenueBoot{
      venue: venue.id
    })
  end

  def parse_response({:error, {venue, reason}}) do
    Events.error(%Events.VenueBootError{
      venue: venue.id,
      reason: reason
    })
  end
end
