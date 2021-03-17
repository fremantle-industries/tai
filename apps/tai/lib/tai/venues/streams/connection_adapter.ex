defmodule Tai.Venues.Streams.ConnectionAdapter do
  alias __MODULE__

  @type state :: ConnectionAdapter.State.t
  @type msg :: term

  @callback on_terminate(WebSockex.close_reason, state) :: :ok
  @callback on_connect(WebSockex.Conn.t, state) :: :ok
  @callback on_disconnect(WebSockex.connection_status_map, state) :: :ok
  @callback on_msg(msg, state) :: {:ok, state}

  defmodule Requests do
    @type next_request_id :: non_neg_integer
    @type t :: %Requests{
            next_request_id: next_request_id,
            pending_requests: %{
              optional(next_request_id) => pos_integer
            }
          }

    @enforce_keys ~w[next_request_id pending_requests]a
    defstruct ~w[next_request_id pending_requests]a
  end

  defmodule State do
    @type channel_name :: atom
    @type route :: :auth | :order_books | :optional_channels
    @type t :: %State{
            venue: Tai.Venue.id,
            routes: %{required(route) => atom},
            channels: [channel_name],
            credential: {Tai.Venue.credential_id, map} | nil,
            products: [Tai.Venues.Product.t],
            quote_depth: pos_integer,
            heartbeat_interval: pos_integer,
            heartbeat_timeout: pos_integer,
            heartbeat_timer: reference | nil,
            heartbeat_timeout_timer: reference | nil,
            compression: :unzip | :gunzip | nil,
            requests: Requests.t | nil,
            opts: map,
          }

    @enforce_keys ~w[
      venue
      routes
      channels
      products
      quote_depth
      heartbeat_interval
      heartbeat_timeout
      opts
    ]a
    defstruct ~w[
      venue
      routes
      channels
      credential
      products
      quote_depth
      heartbeat_interval
      heartbeat_timeout
      heartbeat_timer
      heartbeat_timeout_timer
      compression
      requests
      opts
    ]a
  end

  defmodule Events do
    def connect(venue) do
      TaiEvents.info(%Tai.Events.StreamConnect{venue: venue})
    end

    def disconnect(conn_status, venue) do
      TaiEvents.warn(%Tai.Events.StreamDisconnect{
        venue: venue,
        reason: conn_status.reason
      })
    end

    def terminate(close_reason, venue) do
      TaiEvents.warn(%Tai.Events.StreamTerminate{venue: venue, reason: close_reason})
    end
  end

  defmodule Topics do
    @topic {:venues, :stream}

    def broadcast(venue, status) do
      Tai.SystemBus.broadcast(@topic, {:venues, :stream, status, venue})
    end
  end

  defmacro __using__(_) do
    quote location: :keep do
      use WebSockex

      @type venue :: Tai.Venue.id()

      @spec process_name(venue) :: atom
      def process_name(venue), do: :"#{__MODULE__}_#{venue}"

      @deprecated "Use Tai.Venues.Streams.ConnectionAdapter.process_name/1 instead."
      @spec to_name(venue) :: atom
      def to_name(venue), do: :"#{__MODULE__}_#{venue}"

      def handle_connect(conn, state) do
        Process.flag(:trap_exit, true)
        Topics.broadcast(state.venue, :connect)
        Events.connect(state.venue)
        on_connect(conn, state)

        {:ok, state}
      end

      def handle_disconnect(conn_status, state) do
        Topics.broadcast(state.venue, :disconnect)
        Events.disconnect(conn_status, state.venue)
        on_disconnect(conn_status, state)

        {:ok, state}
      end

      def terminate(close_reason, state) do
        Topics.broadcast(state.venue, :terminate)
        Events.terminate(close_reason, state.venue)
        on_terminate(close_reason, state)

        {:ok, state}
      end

      def handle_frame({:binary, <<43, 200, 207, 75, 7, 0>> = pong}, state) do
        :zlib
        |> apply(state.compression, [pong])
        |> on_msg(state)
      end

      def handle_frame({:binary, compressed_data}, state) do
        :zlib
        |> apply(state.compression, [compressed_data])
        |> Jason.decode!()
        |> on_msg(state)
      end

      def handle_frame({:text, msg}, state) do
        msg
        |> Jason.decode!()
        |> on_msg(state)
      end

      def on_terminate(_, state), do: {:ok, state}
      def on_connect(_, state), do: {:ok, state}
      def on_disconnect(_, state), do: {:ok, state}
      def on_msg(_, state), do: {:ok, state}
      defoverridable on_terminate: 2, on_connect: 2, on_disconnect: 2, on_msg: 2
    end
  end
end
