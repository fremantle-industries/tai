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
            connect_total: non_neg_integer,
            disconnect_total: non_neg_integer,
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
      connect_total
      disconnect_total
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
      connect_total
      disconnect_total
      requests
      opts
    ]a
  end

  defmodule Telemetry do
    def connect(state) do
      :telemetry.execute(
        [:tai, :venues, :stream, :connect],
        %{total: state.connect_total},
        %{venue: state.venue}
      )
    end

    def disconnect(state) do
      :telemetry.execute(
        [:tai, :venues, :stream, :disconnect],
        %{total: state.disconnect_total},
        %{venue: state.venue}
      )
    end
  end

  defmodule Events do
    def connect(state) do
      TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
    end

    def disconnect(conn_status, state) do
      TaiEvents.warn(%Tai.Events.StreamDisconnect{
        venue: state.venue,
        reason: conn_status.reason
      })
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

      def terminate(close_reason, state) do
        TaiEvents.warn(%Tai.Events.StreamTerminate{venue: state.venue, reason: close_reason})
        on_terminate(close_reason, state)
      end

      def handle_connect(conn, state) do
        state = %{state | connect_total: state.connect_total + 1}
        Telemetry.connect(state)
        Events.connect(state)
        on_connect(conn, state)

        {:ok, state}
      end

      def handle_disconnect(conn_status, state) do
        state = %{state | disconnect_total: state.disconnect_total + 1}
        Telemetry.disconnect(state)
        Events.disconnect(conn_status, state)
        on_disconnect(conn_status, state)

        {:ok, state}
      end

      def handle_frame({:text, msg}, state) do
        msg
        |> Jason.decode!()
        |> on_msg(state)

        {:ok, state}
      end

      def on_terminate(_, _), do: :ok
      def on_connect(_, _), do: :ok
      def on_disconnect(_, _), do: :ok
      def on_msg(_, state), do: {:ok, state}
      defoverridable on_terminate: 2, on_connect: 2, on_disconnect: 2, on_msg: 2
    end
  end
end
