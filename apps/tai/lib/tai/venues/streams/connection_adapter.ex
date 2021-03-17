defmodule Tai.Venues.Streams.ConnectionAdapter do
  alias __MODULE__

  @type state :: ConnectionAdapter.State.t
  @type msg :: term
  @type phase :: :init | atom

  @callback on_terminate(WebSockex.close_reason, state) :: {:ok, state}
  @callback on_connect(WebSockex.Conn.t, state) :: {:ok, state}
  @callback on_disconnect(WebSockex.connection_status_map, state) :: {:ok, state}
  @callback on_msg(msg, state) :: {:ok, state}
  @callback subscribe(phase, state) :: {:ok, state}

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

      @behaviour Tai.Venues.Streams.ConnectionAdapter

      @type venue :: Tai.Venue.id()

      @spec process_name(venue) :: atom
      def process_name(venue), do: :"#{__MODULE__}_#{venue}"

      def handle_connect(conn, state) do
        Process.flag(:trap_exit, true)
        Topics.broadcast(state.venue, :connect)
        Events.connect(state.venue)
        send(self(), {:heartbeat, :start})
        send(self(), {:subscribe, :init})
        on_connect(conn, state)
      end

      def handle_disconnect(conn_status, state) do
        Topics.broadcast(state.venue, :disconnect)
        Events.disconnect(conn_status, state.venue)
        on_disconnect(conn_status, state)
      end

      def terminate(close_reason, state) do
        Topics.broadcast(state.venue, :terminate)
        Events.terminate(close_reason, state.venue)
        on_terminate(close_reason, state)
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

      def handle_pong(:pong, state) do
        state =
          state
          |> cancel_heartbeat_timeout()
          |> schedule_heartbeat()

        {:ok, state}
      end

      def handle_info({:EXIT, pid, :normal}, state) do
        {:ok, state}
      end

      def handle_info({:heartbeat, :start}, state) do
        {:ok, schedule_heartbeat(state)}
      end

      def handle_info({:heartbeat, :ping}, state) do
        {:reply, :ping, schedule_heartbeat_timeout(state)}
      end

      def handle_info({:heartbeat, :timeout}, state) do
        {:close, {1000, "heartbeat timeout"}, state}
      end

      def handle_info({:subscribe, phase}, state) do
        subscribe(phase, state)
      end

      def handle_info({:send_msg, msg}, state) do
        json_msg = Jason.encode!(msg)
        {:reply, {:text, json_msg}, state}
      end

      def on_terminate(_, state), do: {:ok, state}
      def on_connect(_, state), do: {:ok, state}
      def on_disconnect(_, state), do: {:ok, state}
      def on_msg(_, state), do: {:ok, state}
      def subscribe(_, state), do: {:ok, state}
      defoverridable on_terminate: 2, on_connect: 2, on_disconnect: 2, on_msg: 2, subscribe: 2

      defp schedule_heartbeat(state) do
        timer = Process.send_after(self(), {:heartbeat, :ping}, state.heartbeat_interval)
        %{state | heartbeat_timer: timer}
      end

      defp schedule_heartbeat_timeout(state) do
        timer = Process.send_after(self(), {:heartbeat, :timeout}, state.heartbeat_timeout)
        %{state | heartbeat_timeout_timer: timer}
      end

      defp cancel_heartbeat_timeout(state) do
        Process.cancel_timer(state.heartbeat_timeout_timer)
        %{state | heartbeat_timeout_timer: nil}
      end

      defp add_request(state) do
        pending_requests = Map.put(state.requests, state.requests.next_request_id, System.monotonic_time())
        requests = %{state.requests | next_request_id: state.requests.next_request_id + 1, pending_requests: pending_requests}
        %{state | requests: requests}
      end
    end
  end
end
