defmodule Tai.Venues.BootHandler do
  alias Tai.Events

  @type adapter :: Tai.Venues.Adapter.t()
  @type error_reason :: term

  @spec parse_response({:ok, adapter} | {:error, {adapter, error_reason}}) :: no_return
  def parse_response({:ok, adapter}) do
    Events.info(%Events.VenueBoot{
      venue: adapter.id
    })
  end

  def parse_response({:error, {adapter, reason}}) do
    Events.error(%Events.VenueBootError{
      venue: adapter.id,
      reason: reason
    })
  end
end
