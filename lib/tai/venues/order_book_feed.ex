defmodule Tai.Venues.OrderBookFeed do
  @moduledoc """
  Behaviour to connect to a WebSocket that streams quotes from order books
  """

  @type t :: %Tai.Venues.OrderBookFeed{
          feed_id: atom,
          symbols: [atom],
          store: map
        }

  @enforce_keys [:feed_id, :symbols, :store]
  defstruct [:feed_id, :symbols, :store]

  @doc """
  Invoked after the process is started and should be used to setup subscriptions
  """
  @callback subscribe_to_order_books(pid :: pid, feed_id :: atom, symbols :: list) ::
              :ok | {:error, bitstring}

  @doc """
  Invoked after a message is received on the socket and should be used to process the message
  """
  @callback handle_msg(msg :: map, feed :: t) :: {:ok, state :: t}

  @doc """
  Returns an atom that will identify the process

  ## Examples

    iex> Tai.Venues.OrderBookFeed.to_name(:my_test_feed)
    :order_book_feed_my_test_feed
  """
  def to_name(feed_id), do: :"order_book_feed_#{feed_id}"

  defmacro __using__(_) do
    quote location: :keep do
      use WebSockex

      require Logger

      @behaviour Tai.Venues.OrderBookFeed

      def default_url, do: raise("No default_url/0 in #{__MODULE__}")

      def start_link(url, feed_id: feed_id, symbols: symbols) do
        state = %Tai.Venues.OrderBookFeed{feed_id: feed_id, symbols: symbols, store: %{}}

        url
        |> build_connection_url(symbols)
        |> WebSockex.start_link(
          __MODULE__,
          state,
          name: feed_id |> Tai.Venues.OrderBookFeed.to_name()
        )
        |> init_subscriptions(state)
      end

      def start_link([feed_id: feed_id, symbols: symbols] = args) do
        default_url()
        |> start_link(args)
      end

      @doc """
      Add the registered process name as logger metadata after the websocket has connected
      """
      def handle_connect(_conn, state) do
        Tai.MetaLogger.init_tid()
        Logger.info("connected")

        {:ok, state}
      end

      @doc """
      Hook to create a connection URL with symbols
      """
      def build_connection_url(url, symbols), do: url

      # state should use the type Tai.Venues.OrderBookFeed.t but there is 
      # and outstanding dialyzer problem.
      # https://github.com/elixir-lang/elixir/issues/7700
      @spec init_subscriptions(
              {:ok, pid} | {:error, term},
              state :: Tai.Venues.OrderBookFeed.t()
            ) :: {:ok, pid} | {:error | term}
      defp(init_subscriptions(_websockex_result, _state))

      defp init_subscriptions({:ok, pid}, %Tai.Venues.OrderBookFeed{
             feed_id: feed_id,
             symbols: symbols
           }) do
        pid
        |> subscribe_to_order_books(feed_id, symbols)
        |> case do
          :ok ->
            {:ok, pid}

          {:error, _} = error ->
            error
        end
      end

      defp init_subscriptions(
             {:error, %WebSockex.RequestError{code: 429, message: "Too Many Requests"}} = error,
             %Tai.Venues.OrderBookFeed{feed_id: feed_id}
           ) do
        Logger.error(
          "Could not connect to feed: #{inspect(feed_id)}. Too many requests. Try again later."
        )

        error
      end

      defp init_subscriptions(
             {:error, reason} = error,
             %Tai.Venues.OrderBookFeed{feed_id: feed_id}
           ) do
        Logger.error(
          "could not connect to feed: #{inspect(feed_id)} - reason: #{inspect(reason)}"
        )

        error
      end

      @doc false
      def handle_frame({:text, msg}, %Tai.Venues.OrderBookFeed{feed_id: feed_id} = state) do
        Logger.debug(fn -> "received msg: #{msg}" end)

        msg
        |> Poison.decode!()
        |> handle_msg(state)
        |> case do
          {:ok, new_state} -> {:ok, new_state}
        end
      end

      @doc false
      def handle_disconnect(conn_status, state) do
        Logger.error("disconnected - reason: #{inspect(conn_status.reason)}")

        {:ok, state}
      end

      defoverridable build_connection_url: 2, default_url: 0, handle_disconnect: 2
    end
  end
end
