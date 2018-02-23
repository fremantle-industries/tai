defmodule Tai.Advisor do
  @moduledoc """
  A behavior for implementing a server that receives messages of order book quotes.

  It can be used to monitor multiple quote streams and create, update or cancel orders.
  """

  @doc """
  Callbacks for interacting with order book and trade events
  """
  @callback handle_quotes(state :: term, feed_id :: term, symbol :: term, changes :: term) :: {:ok, orders :: term}

  @doc """
  Returns an atom that will identify the process

  ## Examples

    iex> Tai.Advisor.to_name(:my_test_advisor)
    :advisor_my_test_advisor
  """
  def to_name(advisor_id), do: :"advisor_#{advisor_id}"

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      require Logger

      alias Tai.Advisor

      @behaviour Advisor

      def start_link(advisor_id) do
        GenServer.start_link(
          __MODULE__,
          %{advisor_id: advisor_id},
          name: advisor_id |> Advisor.to_name
        )
      end

      @doc false
      def init(state) do
        Tai.PubSub.subscribe(:order_book)

        {:ok, state}
      end

      @doc false
      def handle_info({:quotes, feed_id, symbol, changes}, state) do
        state
        |> handle_quotes(feed_id, symbol, changes)

        {:noreply, state}
      end
    end
  end
end
