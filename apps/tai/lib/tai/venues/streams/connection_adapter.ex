defmodule Tai.Venues.Streams.ConnectionAdapter do
  @type state :: term
  @type msg :: term

  @callback on_terminate(WebSockex.close_reason, state) :: :ok
  @callback on_connect(WebSockex.Conn.t, state) :: :ok
  @callback on_disconnect(WebSockex.connection_status_map, state) :: :ok
  @callback on_msg(msg, state) :: :ok

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type channel_name :: atom
    @type route :: :auth | :order_books | :optional_channels
    @type t :: %State{
            venue: venue_id,
            routes: %{required(route) => atom},
            channels: [channel_name],
            credential: {credential_id, map} | nil,
            products: [product],
            quote_depth: pos_integer,
            opts: map,
            heartbeat_interval: pos_integer,
            heartbeat_timeout: pos_integer,
            heartbeat_timer: reference | nil,
            heartbeat_timeout_timer: reference | nil
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
      opts
    ]a
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
        TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
        on_connect(conn, state)
        {:ok, state}
      end

      def handle_disconnect(conn_status, state) do
        TaiEvents.warn(%Tai.Events.StreamDisconnect{
          venue: state.venue,
          reason: conn_status.reason
        })
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
      def on_msg(_, _), do: :ok
      defoverridable on_terminate: 2, on_connect: 2, on_disconnect: 2, on_msg: 2
    end
  end
end
