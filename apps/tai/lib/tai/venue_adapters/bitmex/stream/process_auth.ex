defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth do
  use GenServer
  alias __MODULE__

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type t :: %State{
            venue: venue_id,
            credential_id: credential_id
          }

    @enforce_keys ~w(venue credential_id)a
    defstruct ~w(venue credential_id)a
  end

  @type venue_id :: Tai.Venue.id()
  @type credential :: Tai.Venue.credential()

  @spec start_link(venue: venue_id, credential: credential) :: GenServer.on_start()
  def start_link(venue: venue, credential: {credential_id, _}) do
    state = %State{venue: venue, credential_id: credential_id}
    name = to_name(venue)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def init(state) do
    {:ok, state}
  end

  def handle_cast({venue_msg, received_at}, state) do
    venue_msg
    |> extract()
    |> process(received_at, state)

    {:noreply, state}
  end

  def extract(msg) do
    ProcessAuth.VenueMessage.extract(msg)
  end

  defp process(messages, received_at, state) do
    messages
    |> Enum.map(&ProcessAuth.Message.process(&1, received_at, state))
  end
end
