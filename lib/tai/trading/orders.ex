defmodule Tai.Trading.Orders do
  @moduledoc """
  Converts submissions into orders and keeps track of them for updates
  """

  use GenServer

  alias Tai.Trading.Order

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:clear, _from, _state) do
    {:reply, :ok, %{}}
  end

  def handle_call(:count, _from, state) do
    {:reply, Enum.count(state), state}
  end

  def handle_call({:add, submissions}, _from, state) do
    {new_orders, new_state} = add_orders(submissions, state)

    {:reply, new_orders, new_state}
  end

  def handle_call({:get, client_id}, _from, state) do
    {:reply, Map.get(state, client_id), state}
  end

  def handle_call({:update, client_id, attrs}, _from, state) do
    {_previous_order, new_state} = Map.get_and_update(
      state,
      client_id,
      fn current_order ->
        attr_whitelist = [:server_id, :created_at]
        accepted_attrs = attrs |> Keyword.take(attr_whitelist) |> Map.new
        updated_order = current_order |> Map.merge(accepted_attrs)

        {current_order, updated_order}
      end
    )
    updated_order = new_state[client_id]

    {:reply, updated_order, new_state}
  end

  @doc """
  Deletes all existing tracked orders
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  Returns the number of tracked orders
  """
  def count do
    GenServer.call(__MODULE__, :count)
  end

  @doc """
  Creates orders from the submissions.

  - Assigning a client id in the uuid v4 format
  - Tracks the order
  """
  def add(submissions) do
    GenServer.call(__MODULE__, {:add, submissions})
  end

  @doc """
  Returns the order matching the client_id or nil otherwise
  """
  def get(client_id) do
    GenServer.call(__MODULE__, {:get, client_id})
  end

  @doc """
  Update the whitelisted attributes for the given order
  """
  def update(client_id, attributes \\ %{}) do
    GenServer.call(__MODULE__, {:update, client_id, attributes})
  end

  defp add_orders({_exchange, _symbol, _price, _size} = submission, state) do
    [submission]
    |> add_orders(state)
  end
  defp add_orders([_head | _tail] = submissions, state) do
    submissions
    |> add_orders(state, [])
  end
  defp add_orders([], state, new_orders), do: {new_orders |> Enum.reverse, state}
  defp add_orders([{exchange_id, symbol, price, size} | tail], state, new_orders) do
    order = %Order{
      client_id: UUID.uuid4(),
      exchange: exchange_id,
      symbol: symbol,
      price: price,
      size: size,
      enqueued_at: Timex.now
    }
    new_state = state |> Map.put(order.client_id, order)

    add_orders(tail, new_state, [order | new_orders])
  end
end
