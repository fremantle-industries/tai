defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth do
  use GenServer
  alias __MODULE__

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Tai.Venue.id()

  def start_link(venue_id: venue) do
    state = %State{venue: venue}
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

  defdelegate extract(msg), to: ProcessAuth.VenueMessage

  defp process(messages, received_at, state) do
    messages
    |> Enum.map(&ProcessAuth.Message.process(&1, received_at, state))
  end
end
