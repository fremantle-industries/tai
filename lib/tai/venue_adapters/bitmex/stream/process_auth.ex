defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type t :: %State{venue_id: venue_id, tasks: map}

    @enforce_keys ~w(venue_id tasks)a
    defstruct ~w(venue_id tasks)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()

  def start_link(venue_id: venue_id) do
    state = %State{venue_id: venue_id, tasks: %{}}
    name = venue_id |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_cast({msg, _received_at}, state) do
    {:ok, new_state} =
      msg
      |> transform()
      |> process_action(state)

    {:noreply, new_state}
  end

  # TODO: Handle the return values of async tasks
  def handle_info(_msg, state), do: {:noreply, state}

  @transformers [
    ProcessAuth.TransformMessages.UpdateOrders,
    ProcessAuth.TransformMessages.NoOp
  ]
  defp transform(msg), do: msg |> transform(@transformers)

  defp transform(msg, []), do: msg |> ProcessAuth.TransformMessages.Unhandled.from_venue()

  defp transform(msg, [transformer | to_check]) do
    msg
    |> transformer.from_venue()
    |> case do
      {:ok, _} = result -> result
      {:error, :not_handled} -> msg |> transform(to_check)
    end
  end

  defp process_action({:ok, action}, state) do
    {:ok, _} = result = action |> ProcessAuth.Message.process(state)
    result
  end
end
