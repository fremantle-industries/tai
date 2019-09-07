defprotocol Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @type message :: struct
  @type received_at :: DateTime.t()
  @type state :: ProcessAuth.State.t()

  @spec process(message, received_at, state) :: :ok
  def process(message, received_at, state)
end
