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
  def to_name(feed_id) do
    :"order_book_feed_#{feed_id}"
  end

  defmacro __using__(_) do
    quote location: :keep do
      use WebSockex

      require Logger

      alias Tai.Exchanges.Config

      @behaviour Tai.Exchanges.OrderBookFeed

      def url, do: raise "No url/0 in #{__MODULE__}"

      def start_link(feed_id) do
        url()
        |> WebSockex.start_link(
          __MODULE__,
          feed_id,
          name: feed_id |> Tai.Exchanges.OrderBookFeed.to_name
        )
        |> init_subscriptions(feed_id)
      end

      @doc false
      defp init_subscriptions({:ok, pid}, feed_id) do
        pid
        |> subscribe_to_order_books(feed_id |> Config.order_book_feed_symbols)
        |> case do
          :ok -> {:ok, pid}
          :error -> {:error, "could not subscribe to order books"}
        end
      end
      @doc false
      defp init_subscriptions({:error, reason}, feed_id) do
        {:error, reason}
      end

      @doc false
      def handle_frame({:text, msg}, feed_id) do
        Logger.debug "#{feed_id |> Tai.Exchanges.OrderBookFeed.to_name} msg: #{msg}"

        msg
        |> JSON.decode!
        |> parse_msg(feed_id)

        {:ok, feed_id}
      end
      @doc false
      def handle_frame({type, msg}, state) do
        Logger.debug "Unhandled frame #{__MODULE__} - type: #{inspect type}, msg: #{inspect msg}"

        {:ok, state}
      end

      @doc false
      defp parse_msg(msg, feed_id) do
        Logger.debug "#{feed_id |> Tai.Exchanges.OrderBookFeed.to_name} received msg: #{inspect msg}"

        msg
        |> handle_msg(feed_id)
      end

      def handle_disconnect(conn_status, feed_id) do
        Logger.error "#{feed_id |> Tai.Exchanges.OrderBookFeed.to_name} disconnected - reason: #{inspect conn_status.reason}"

        {:ok, feed_id}
      end

      defoverridable [url: 0]
    end
  end
end
