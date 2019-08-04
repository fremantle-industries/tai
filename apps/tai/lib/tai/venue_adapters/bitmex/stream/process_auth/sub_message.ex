defprotocol Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.SubMessage do
  alias Tai.VenueAdapters.Bitmex

  @type action :: struct
  @type state :: Bitmex.Stream.ProcessAuth.State.t()
  @type received_at :: DateTime.t()
  @type new_state :: Bitmex.Stream.ProcessAuth.State.t()

  @spec process(action, received_at, state) :: {:ok, new_state}
  def process(action, received_at, state)
end
