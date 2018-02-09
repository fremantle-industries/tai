defmodule Tai.Exchanges.OrderBookFeed do
  @doc """
  Invoked when setting up subscriptions
  """
  @callback subscribe_to_order_books(pid :: term, symbols :: term) :: :ok | :error

  def to_name(id) do
    "order_book_feed_#{id}"
    |> String.to_atom
  end

  defmacro __using__(_) do
    quote location: :keep do
      use WebSockex

      require Logger

      alias Tai.Exchanges.Config

      @behaviour Tai.Exchanges.OrderBookFeed

      defp url, do: raise "No url/0 in #{__MODULE__}"

      def start_link(id) do
        url()
        |> WebSockex.start_link(
          __MODULE__,
          id,
          name: id |> Tai.Exchanges.OrderBookFeed.to_name
        )
        |> init_subscriptions(id)
      end

      @doc false
      defp init_subscriptions({:ok, pid}, id) do
        pid
        |> subscribe_to_order_books(id |> Config.order_book_feed_symbols)
        |> case do
          :ok -> {:ok, pid}
          :error -> {:error, "could not subscribe to order books"}
        end
      end
      @doc false
      defp init_subscriptions({:error, reason}) do
        {:error, reason}
      end

      @doc false
      def subscribe_to_order_books(pid, symbols) do
        raise "No subscribe_to_order_books/2 in #{__MODULE__} for #{inspect pid}, #{inspect symbols}"
      end

      @doc false
      def handle_frame({:text, msg}, id) do
        Logger.debug "#{id |> Tai.Exchanges.OrderBookFeed.to_name} msg: #{msg}"

        msg
        |> JSON.decode!
        |> parse_msg(id)

        {:ok, id}
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

      @doc false
      defp handle_msg(msg, name) do
        raise "No handle_msg/2 clause in #{__MODULE__} provided for #{inspect msg}, #{inspect name}"
      end

      @doc false
      def handle_disconnect(conn_status, id) do
        Logger.error "#{id |> Tai.Exchanges.OrderBookFeed.to_name} disconnected - reason: #{inspect conn_status.reason}"

        {:ok, id}
      end

      defoverridable [handle_msg: 2, subscribe_to_order_books: 2, url: 0]
    end
  end
end
