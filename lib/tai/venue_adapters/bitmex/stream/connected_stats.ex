defmodule Tai.VenueAdapters.Bitmex.Stream.ConnectedStats do
  def broadcast(
        %{"bots" => bots, "users" => users},
        venue_id,
        received_at
      ) do
    Tai.Events.info(%Tai.Events.ConnectedStats{
      venue_id: venue_id,
      received_at: received_at,
      bots: bots,
      users: users
    })
  end
end
