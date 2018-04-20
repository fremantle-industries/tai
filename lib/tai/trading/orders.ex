defmodule Tai.Trading.Orders do
  @moduledoc """
  Converts submissions into orders and keeps track of them for updates
  """

  use GenServer

  alias Tai.Trading.{Order, OrderStatus, OrderSubmission}

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

  def handle_call({:add, submissions}, _from, state) do
    {new_orders, new_state} = add_orders(submissions, state)

    {:reply, new_orders, new_state}
  end

  def handle_call({:update, client_id, attrs}, _from, state) do
    {_previous_order, new_state} =
      Map.get_and_update(state, client_id, fn current_order ->
        attr_whitelist = [:server_id, :created_at, :status]
        accepted_attrs = attrs |> Keyword.take(attr_whitelist) |> Map.new()
        updated_order = current_order |> Map.merge(accepted_attrs)

        {current_order, updated_order}
      end)

    updated_order = new_state[client_id]

    {:reply, updated_order, new_state}
  end

  def handle_call({:find, client_id}, _from, state) do
    {:reply, Map.get(state, client_id), state}
  end

  def handle_call(:all, _from, state) do
    {:reply, state |> Map.values(), state}
  end

  def handle_call({:where, [_head | _tail] = filters}, _from, state) do
    {:reply, state |> filter(filters) |> Map.values(), state}
  end

  def handle_call(:count, _from, state) do
    {:reply, state |> Enum.count(), state}
  end

  def handle_call({:count, status: status}, _from, state) do
    {:reply, state |> filter(status: status) |> Enum.count(), state}
  end

  @doc """
  Deletes the record of all existing orders
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
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
  Update the whitelisted attributes for the given order

  - server_id
  - created_at
  - status
  """
  def update(client_id, attributes \\ %{}) do
    GenServer.call(__MODULE__, {:update, client_id, attributes})
  end

  @doc """
  Return the order matching the client_id or nil otherwise
  """
  def find(client_id) do
    GenServer.call(__MODULE__, {:find, client_id})
  end

  @doc """
  Return a list of all the orders
  """
  def all do
    GenServer.call(__MODULE__, :all)
  end

  @doc """
  Return a list of orders filtered by their attributes
  """
  def where([_head | _tail] = filters) do
    GenServer.call(__MODULE__, {:where, filters})
  end

  @doc """
  Return the total number of orders
  """
  def count do
    GenServer.call(__MODULE__, :count)
  end

  @doc """
  Return the total number of orders with the given status
  """
  def count(status: status) do
    GenServer.call(__MODULE__, {:count, status: status})
  end

  defp add_orders({_exchange, _symbol, _price, _size} = submission, state) do
    [submission]
    |> add_orders(state)
  end

  defp add_orders(%OrderSubmission{} = submission, state) do
    [submission]
    |> add_orders(state)
  end

  defp add_orders([], state), do: {[], state}

  defp add_orders([_head | _tail] = submissions, state) do
    submissions
    |> add_orders(state, [])
  end

  defp add_orders([], state, new_orders), do: {new_orders |> Enum.reverse(), state}

  defp add_orders([%OrderSubmission{} = submission | tail], state, new_orders) do
    order = %Order{
      client_id: UUID.uuid4(),
      exchange: submission.exchange_id,
      symbol: submission.symbol,
      side: submission.side,
      type: submission.type,
      price: abs(submission.price),
      size: abs(submission.size),
      status: OrderStatus.enqueued(),
      enqueued_at: Timex.now()
    }

    new_state = state |> Map.put(order.client_id, order)

    add_orders(tail, new_state, [order | new_orders])
  end

  defp filter(state, [{attr, [_head | _tail] = vals}]) do
    state
    |> Enum.filter(fn {_, order} ->
      vals
      |> Enum.any?(&(&1 == Map.get(order, attr)))
    end)
    |> Map.new()
  end

  defp filter(state, [{attr, val}]) do
    state
    |> Enum.filter(fn {_, order} -> Map.get(order, attr) == val end)
    |> Map.new()
  end

  defp filter(state, [{_attr, _val} = head | tail]) do
    state
    |> filter([head])
    |> filter(tail)
  end
end
