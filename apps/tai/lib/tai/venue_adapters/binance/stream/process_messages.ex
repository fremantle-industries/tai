defmodule Tai.VenueAdapters.Binance.Stream.ProcessMessages do
  use GenServer
  alias Tai.VenueAdapters.Binance.Stream

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type t :: %Stream.ProcessMessages{venue_id: venue_id}

  @enforce_keys ~w(venue_id)a
  defstruct ~w(venue_id)a

  def start_link(venue_id: venue_id) do
    state = %Stream.ProcessMessages{venue_id: venue_id}
    GenServer.start_link(__MODULE__, state, name: venue_id |> to_name())
  end

  def init(state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_cast({msg, received_at}, state) do
    %Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: msg,
      received_at: received_at
    }
    |> Tai.Events.info()

    {:noreply, state}
  end
end
