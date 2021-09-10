defmodule Tai.Boot do
  use GenServer
  require Logger

  defmodule State do
    @enforce_keys ~w[config venues venue_replies]a
    defstruct ~w[config venues venue_replies]a
  end

  @type id :: atom
  @type venue :: Tai.Venue.t()

  @default_id :default

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      shutdown: 5_000,
      restart: :transient,
      type: :worker
    }
  end

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    config = Keyword.get(args, :config, Tai.Config.parse())
    name = to_name(id)
    state = %State{config: config, venues: %{}, venue_replies: %{}}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(id) :: atom
  def to_name(id) do
    :"#{__MODULE__}_#{id}"
  end

  @spec register_venue(venue) :: {:ok, venue}
  @spec register_venue(venue, id) :: {:ok, venue}
  def register_venue(venue, id \\ @default_id) do
    id
    |> to_name
    |> GenServer.call({:register_venue, venue})
  end

  @spec close_registration :: :ok
  @spec close_registration(id) :: :ok
  def close_registration(id \\ @default_id) do
    id
    |> to_name
    |> GenServer.cast(:close_registration)
  end

  @events [Tai.Events.VenueStart, Tai.Events.VenueStartError]
  def init(state) do
    Enum.each(@events, &TaiEvents.subscribe/1)
    {:ok, state}
  end

  def handle_call({:register_venue, venue}, _from, state) do
    state = %{
      state
      | venues: Map.put(state.venues, venue.id, venue)
    }

    {:reply, {:ok, venue}, state}
  end

  def handle_cast(:close_registration, state) do
    {
      :noreply,
      state,
      {:continue, :check_replies_for_completion}
    }
  end

  def handle_info({TaiEvents.Event, %Tai.Events.VenueStart{} = event, :info}, state) do
    state = %{
      state
      | venue_replies: Map.put(state.venue_replies, event.venue, event)
    }

    {
      :noreply,
      state,
      {:continue, :check_replies_for_completion}
    }
  end

  def handle_info({TaiEvents.Event, %Tai.Events.VenueStartError{} = event, :error}, state) do
    state = %{
      state
      | venue_replies: Map.put(state.venue_replies, event.venue, event)
    }

    {
      :noreply,
      state,
      {:continue, :check_replies_for_completion}
    }
  end

  def handle_continue(:check_replies_for_completion, state) do
    state
    |> all_venues_replied?()
    |> check_replies()
    |> case do
      :noop -> {:noreply, state}
      :stop -> {:stop, :normal, state}
    end
  end

  def all_venues_replied?(state) do
    if Enum.count(state.venue_replies) == Enum.count(state.venues) do
      {:ok, state}
    else
      {:noop, state}
    end
  end

  defp check_replies({:ok, state}) do
    state.venue_replies
    |> all_venue_replies_started?()
    |> case do
      true ->
        {:ok, {loaded_fleets, loaded_advisors}} = Tai.Fleets.load(state.config.fleets)
        {advisors_started, _} = Tai.Advisors.start(where: [start_on_boot: true])

        %Tai.Events.BootAdvisors{
          loaded_fleets: loaded_fleets,
          loaded_advisors: loaded_advisors,
          started_advisors: advisors_started
        }
        |> TaiEvents.info()

        state.config.after_boot
        |> case do
          {mod, func_name} -> apply(mod, func_name, [])
          {mod, func_name, args} -> apply(mod, func_name, [args])
          _ -> nil
        end

      false ->
        error_event = %Tai.Events.BootAdvisorsError{reason: venue_errors(state.venue_replies)}
        TaiEvents.error(error_event)

        state.config.after_boot_error
        |> case do
          {mod, func_name} -> apply(mod, func_name, [error_event])
          _ -> nil
        end
    end

    :stop
  end

  defp check_replies({:noop, _}), do: :noop

  defp all_venue_replies_started?(venue_replies) do
    venue_replies
    |> Enum.all?(fn
      {_, %r{}} -> r == Tai.Events.VenueStart
    end)
  end

  defp venue_errors(venue_replies) do
    venue_replies
    |> Enum.map(fn
      {venue_id, %Tai.Events.VenueStartError{reason: reason}} ->
        {venue_id, reason}

      {_venue_id, %Tai.Events.VenueStart{}} ->
        nil
    end)
    |> Enum.filter(& &1)
  end
end
