defmodule Tai.Exchanges.OrderBookFeed do
  @moduledoc """
  Behaviour to connect to a WebSocket that streams quotes from order books
  """

  @doc """
  Invoked after the process is started and should be used to setup subscriptions
  """
  @callback subscribe_to_order_books(pid :: Pid.t, symbols :: List.t) :: :ok | :error

  @doc """
  Invoked after a message is received on the socket and should be used to process the message
  """
  @callback handle_msg(msg :: Map.t, feed_id :: Atom.t) :: nil

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

      def default_url, do: raise "No default_url/0 in #{__MODULE__}"

      def start_link(url, feed_id: feed_id, symbols: symbols) do
        url
        |> WebSockex.start_link(
          __MODULE__,
          feed_id,
          name: feed_id |> Tai.Exchanges.OrderBookFeed.to_name
        )
        |> init_subscriptions(feed_id, symbols)
      end

      def start_link([feed_id: feed_id, symbols: symbols] = args) do
        default_url()
        |> start_link(args)
      end

      @doc false
      defp init_subscriptions({:ok, pid}, feed_id, symbols) do
        pid
        |> subscribe_to_order_books(symbols)
        |> case do
          :ok -> {:ok, pid}
          :error -> {:error, "could not subscribe to order books"}
        end
      end
      @doc false
      defp init_subscriptions({:error, reason}, feed_id, symbols) do
        {:error, reason}
      end

      @doc false
      def handle_frame({:text, msg}, feed_id) do
        Logger.debug "[#{feed_id |> Tai.Exchanges.OrderBookFeed.to_name}] received msg: #{msg}"

        msg
        |> parse_msg(feed_id)

        {:ok, feed_id}
      end

      @doc false
      defp parse_msg(msg, feed_id) do
        msg
        |> JSON.decode!
        |> handle_msg(feed_id)
      end

      @doc false
      def handle_disconnect(conn_status, feed_id) do
        Logger.error "[#{feed_id |> Tai.Exchanges.OrderBookFeed.to_name}] disconnected - reason: #{inspect conn_status.reason}"

        {:ok, feed_id}
      end

      defoverridable [default_url: 0, handle_disconnect: 2]
    end
  end
end
