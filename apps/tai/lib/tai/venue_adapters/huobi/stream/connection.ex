defmodule Tai.VenueAdapters.Huobi.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Huobi.Stream

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type channel_name :: atom
    @type route :: :order_books | :optional_channels
    @type last_pong :: integer
    @type request_id :: non_neg_integer
    @type t :: %State{
            venue: venue_id,
            routes: %{required(route) => atom},
            channels: [channel_name],
            credential: {credential_id, map},
            products: [product],
            last_pong: pos_integer,
            next_request_id: request_id,
            requests: %{
              optional(request_id) => pos_integer
            }
          }

    @enforce_keys ~w(venue routes channels credential products last_pong next_request_id requests)a
    defstruct ~w(venue routes channels credential products last_pong next_request_id requests)a
  end

  @type stream :: Tai.Venues.Stream.t()
  @type endpoint :: String.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.account()
  @type msg :: map | String.t()
  @type state :: State.t()

  @spec start_link(
          endpoint: endpoint,
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid}
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
    routes = %{
      order_books: stream.venue.id |> Stream.RouteOrderBooks.to_name(),
      optional_channels: stream.venue.id |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue: stream.venue.id,
      routes: routes,
      channels: stream.venue.channels,
      credential: credential,
      products: stream.products,
      last_pong: time_now(),
      next_request_id: 1,
      requests: %{}
    }

    name = to_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def terminate(close_reason, state) do
    TaiEvents.warn(%Tai.Events.StreamTerminate{venue: state.venue, reason: close_reason})
  end

  def handle_connect(_conn, state) do
    TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
    send(self(), :init_subscriptions)
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    TaiEvents.warn(%Tai.Events.StreamDisconnect{
      venue: state.venue,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  def handle_info(:init_subscriptions, state) do
    state.products |> Enum.each(&send(self(), {:subscribe, :depth, &1}))
    {:ok, state}
  end

  def handle_info({:subscribe, :depth, product}, state) do
    msg =
      %{
        sub: Stream.Channels.depth(product),
        data_type: "incremental",
        id: Integer.to_string(state.next_request_id)
      }
      |> Jason.encode!()

    state = add_request(state)
    {:reply, {:text, msg}, state}
  end

  def handle_frame({:binary, compressed_data}, state) do
    compressed_data
    |> :zlib.gunzip()
    |> Jason.decode!()
    |> handle_msg(state)
  end

  def handle_frame({:text, _}, state), do: {:ok, state}

  defp handle_msg(%{"ch" => "market." <> _} = msg, state) do
    msg |> forward(:order_books, state)
    {:ok, state}
  end

  defp handle_msg(%{"ping" => timestamp}, state) do
    msg = Jason.encode!(%{"pong" => timestamp})
    {:reply, {:text, msg}, state}
  end

  defp handle_msg(%{"id" => id}, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
    {:ok, state}
  end

  defp handle_msg(msg, state) do
    msg |> forward(:optional_channels, state)
    {:ok, state}
  end

  defp add_request(state) do
    requests = Map.put(state.requests, state.next_request_id, :os.system_time(:millisecond))
    %{state | next_request_id: state.next_request_id + 1, requests: requests}
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, Timex.now()})
  end

  defp time_now() do
    :erlang.system_time(:seconds)
  end
end
