defmodule Tai.Exchanges.OrderBookFeed do
  @moduledoc """
  Behaviour to connect to a WebSocket that streams quotes from order books
  """

  @typedoc """
  The state of the running order book feed
  """
  @type t :: Tai.Exchanges.OrderBookFeed

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
  @callback handle_msg(msg :: map, feed_id :: atom) ::
              {:ok, state :: Tai.Exchanges.OrderBookFeed.t()}

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

      @behaviour Tai.Exchanges.OrderBookFeed

      def default_url, do: raise("No default_url/0 in #{__MODULE__}")

      def start_link(url, feed_id: feed_id, symbols: symbols) do
        state = %Tai.Exchanges.OrderBookFeed{feed_id: feed_id, symbols: symbols, store: %{}}

        url
        |> build_connection_url(symbols)
        |> WebSockex.start_link(
          __MODULE__,
          state,
          name: feed_id |> Tai.Exchanges.OrderBookFeed.to_name()
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
        Tai.MetaLogger.init_pname()
        Logger.info("connected")

        {:ok, state}
      end

      @doc """
      Hook to create a connection URL with symbols
      """
      def build_connection_url(url, symbols), do: url

      # state should use the type Tai.Exchanges.OrderBookFeed.t but there is 
      # and outstanding dialyzer problem.
      # https://github.com/elixir-lang/elixir/issues/7700
      @spec init_subscriptions({:ok, pid} | {:error, term}, state :: term) ::
              {:ok, pid} | {:error | term}
      defp(init_subscriptions(_websockex_result, _state))

      defp init_subscriptions({:ok, pid}, %Tai.Exchanges.OrderBookFeed{
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

      defp init_subscriptions({:error, _} = error, %Tai.Exchanges.OrderBookFeed{}), do: error

      @doc false
      def handle_frame({:text, msg}, %Tai.Exchanges.OrderBookFeed{feed_id: feed_id} = state) do
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
