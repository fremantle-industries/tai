defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuthMessages do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream
  require Logger

  @type t :: %Stream.ProcessAuthMessages{
          venue_id: atom
        }

  @enforce_keys [:venue_id]
  defstruct [:venue_id]

  def start_link(venue_id: venue_id) do
    state = %Stream.ProcessAuthMessages{venue_id: venue_id}
    GenServer.start_link(__MODULE__, state, name: venue_id |> to_name())
  end

  def init(state), do: {:ok, state}

  @spec to_name(venue_id :: atom) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_cast(
        {%{"table" => "position", "data" => _data, "action" => "partial"}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "position", "data" => positions, "action" => "update"}, received_at},
        state
      ) do
    positions
    |> Enum.each(fn %{"symbol" => exchange_symbol} = p ->
      Tai.Events.broadcast(%Tai.Events.PositionUpdate{
        venue_id: state.venue_id,
        symbol: exchange_symbol |> String.downcase() |> String.to_atom(),
        received_at: received_at,
        data: p
      })
    end)

    {:noreply, state}
  end

  def handle_cast({%{"table" => "wallet", "action" => "partial"}, _received_at}, state) do
    {:noreply, state}
  end

  def handle_cast({%{"table" => "margin", "action" => "partial"}, _received_at}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "margin", "action" => "update", "data" => _data}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast({%{"table" => "execution", "action" => "partial"}, _received_at}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "execution", "action" => "insert", "data" => _data}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast({%{"table" => "transact", "action" => "partial"}, _received_at}, state) do
    {:noreply, state}
  end
end
