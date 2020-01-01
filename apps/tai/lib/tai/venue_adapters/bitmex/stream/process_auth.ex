defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth do
  use GenServer
  alias __MODULE__

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue_id: venue_id, tasks: map}

    @enforce_keys ~w(venue_id tasks)a
    defstruct ~w(venue_id tasks)a
  end

  @type venue_id :: Tai.Venue.id()

  def start_link(venue_id: venue_id) do
    state = %State{venue_id: venue_id, tasks: %{}}
    name = venue_id |> to_name()
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state}

  def handle_cast({venue_msg, received_at}, state) do
    {:ok, new_state} =
      venue_msg
      |> extract()
      |> process(received_at, state)

    {:noreply, new_state}
  end

  def handle_info({ref, :ok}, state) when is_reference(ref) do
    new_tasks = Map.delete(state.tasks, ref)
    new_state = Map.put(state, :tasks, new_tasks)

    {:noreply, new_state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  defdelegate extract(msg), to: ProcessAuth.VenueMessage

  defp process(messages, received_at, state) do
    message_tasks =
      messages
      |> Enum.reduce(
        %{},
        fn msg, tasks ->
          t = Task.async(fn -> ProcessAuth.Message.process(msg, received_at, state) end)
          Map.put(tasks, t.ref, t)
        end
      )

    new_tasks = Map.merge(state.tasks, message_tasks)
    new_state = Map.put(state, :tasks, new_tasks)

    {:ok, new_state}
  end
end
