defprotocol Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.SubMessage do
  alias Tai.VenueAdapters.Bitmex

  @type action :: struct
  @type state :: Bitmex.Stream.ProcessAuth.State.t()
  @type new_state :: Bitmex.Stream.ProcessAuth.State.t()

  @spec process(action, state) :: {:ok, new_state}
  def process(action, state)
end
