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

  def handle_cast(
        {%{"table" => "position", "action" => "partial", "data" => _positions}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "position", "action" => "insert", "data" => _positions}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "position", "action" => "update", "data" => _positions}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "order", "action" => "partial", "data" => _data}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "order", "action" => "insert", "data" => _data}, _received_at},
        state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "order", "action" => "update", "data" => orders}, _received_at},
        state
      ) do
    orders
    |> Enum.each(fn
      %{"orderID" => venue_order_id, "ordStatus" => _} = venue_order ->
        Task.async(fn -> Stream.UpdateOrder.update(venue_order_id, venue_order) end)

      %{"orderID" => _venue_order_id} ->
        :ignore_changes_with_no_status
    end)

    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "execution", "action" => "partial", "data" => _data}, _received_at},
        state
      ) do
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

  def handle_cast({msg, _received_at}, state) do
    Tai.Events.broadcast(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: msg
    })

    {:noreply, state}
  end

  # TODO: Handle this message
  # - Pretty sure this is coming from async order update task when it exits ^
  def handle_info(_msg, state) do
    # IO.puts("!!!!!!!!! IN handle_info - msg: #{inspect(msg)}")
    {:noreply, state}
  end
end
