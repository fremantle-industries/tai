defmodule Tai.Exchanges.OrderBookFeed do
  @moduledoc """
  Behaviour to connect to a WebSocket that streams quotes from order books
  """

  alias Tai.{PubSub, MetaLogger, Exchanges.OrderBookFeed}

  @typedoc """
  The state of the running order book feed
  """
  @type t :: OrderBookFeed

  @enforce_keys [:feed_id, :symbols, :store]
  defstruct [:feed_id, :symbols, :store]

  @doc """
  Invoked after the process is started and should be used to setup subscriptions
  """
  @callback subscribe_to_order_books(pid :: Pid.t(), feed_id :: Atom.t(), symbols :: List.t()) ::
              :ok | :error

  @doc """
  Invoked after a message is received on the socket and should be used to process the message
  """
  @callback handle_msg(msg :: Map.t(), feed_id :: Atom.t()) :: {:ok, state :: OrderBookFeed.t()}

  @doc """
  Returns an atom that will identify the process

  ## Examples

    iex> Tai.Exchanges.OrderBookFeed.to_name(:my_test_feed)
    :order_book_feed_my_test_feed
  """
  def to_name(feed_id), do: :"order_book_feed_#{feed_id}"

  defmacro __using__(_) do
    quote location: :keep do
      use WebSockex

      require Logger

      alias Tai.{Exchanges.OrderBookFeed, PubSub}

      @behaviour Tai.Exchanges.OrderBookFeed

      def default_url, do: raise("No default_url/0 in #{__MODULE__}")

      def start_link(url, feed_id: feed_id, symbols: symbols) do
        state = %OrderBookFeed{feed_id: feed_id, symbols: symbols, store: %{}}

        url
        |> build_connection_url(symbols)
        |> WebSockex.start_link(
          __MODULE__,
          state,
          name: feed_id |> OrderBookFeed.to_name()
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
        MetaLogger.init_pname()

        {:ok, state}
      end

      @doc """
      Hook to create a connection URL with symbols
      """
      def build_connection_url(url, symbols), do: url

      @doc false
      defp init_subscriptions({:ok, pid}, %OrderBookFeed{feed_id: feed_id, symbols: symbols}) do
        pid
        |> subscribe_to_order_books(feed_id, symbols)
        |> case do
          :ok -> {:ok, pid}
          :error -> {:error, "could not subscribe to order books"}
        end
      end

      @doc false
      defp init_subscriptions({:error, reason}, %OrderBookFeed{}) do
        {:error, reason}
      end

      @doc false
      def handle_frame({:text, msg}, %OrderBookFeed{feed_id: feed_id} = state) do
        Logger.debug(fn -> "received msg: #{msg}" end)

        msg
        |> JSON.decode!()
        |> handle_msg(state)
        |> case do
          {:ok, new_state} ->
            {:ok, new_state}

          other ->
            Logger.warn(
              "expected 'handle_msg' to return an {:ok, state} tuple. But it returned: #{
                inspect(other)
              }"
            )

            {:ok, state}
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
