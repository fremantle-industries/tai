defmodule Tai.Trading.OrderStore do
  @moduledoc """
  Converts submissions into orders and keeps track of them for updates
  """

  use GenServer
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
    new_orders =
      submissions
      |> List.wrap()
      |> build_orders

    new_state =
      new_orders
      |> Enum.reduce(
        state,
        fn order, acc -> Map.put(acc, order.client_id, order) end
      )

    {:reply, new_orders, new_state}
  end

  def handle_call({:find, client_id}, _from, state) do
    {:reply, Map.get(state, client_id), state}
  end

  def handle_call({:find_by_and_update, filters, update_attrs}, _from, state) do
    with [current_order] <- state |> filter(filters) |> Map.values(),
         updated_order <-
           Tai.Trading.OrderStore.AttributeWhitelist.apply(
             current_order,
             update_attrs
           ) do
      new_state = Map.put(state, current_order.client_id, updated_order)
      {:reply, {:ok, [current_order, updated_order]}, new_state}
    else
      [] -> {:reply, {:error, :not_found}, state}
      [_head | _tail] -> {:reply, {:error, :multiple_orders_found}, state}
    end
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
    count =
      state
      |> filter(status: status)
      |> Enum.count()

    {:reply, count, state}
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
  Return the order matching the client_id or nil otherwise
  """
  def find(client_id) do
    GenServer.call(__MODULE__, {:find, client_id})
  end

  @doc """
  Find an order by a list of query parameters and update whitelisted 
  attributes in an atomic operation
  """
  def find_by_and_update(query, update_attrs) do
    GenServer.call(__MODULE__, {:find_by_and_update, query, update_attrs})
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

  defp build_orders(submissions) do
    submissions
    |> Enum.reduce(
      [],
      fn %Tai.Trading.OrderSubmission{} = submission, acc ->
        with price <- submission.price |> Decimal.new() |> Decimal.abs(),
             size <- submission.size |> Decimal.new() |> Decimal.abs(),
             enqueued_at <- Timex.now() do
          order = %Tai.Trading.Order{
            client_id: UUID.uuid4(),
            account_id: submission.account_id,
            symbol: submission.symbol,
            side: submission.side,
            type: submission.type,
            price: price,
            size: size,
            time_in_force: submission.time_in_force,
            status: Tai.Trading.OrderStatus.enqueued(),
            enqueued_at: enqueued_at,
            order_updated_callback: submission.order_updated_callback
          }

          [order | acc]
        end
      end
    )
    |> Enum.reverse()
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

  defmodule AttributeWhitelist do
    @whitelist_attrs [
      :created_at,
      :error_reason,
      :executed_size,
      :server_id,
      :status
    ]

    def apply(order, update_attrs) do
      accepted_attrs =
        update_attrs
        |> Keyword.take(@whitelist_attrs)
        |> Map.new()

      Map.merge(order, accepted_attrs)
    end
  end
end
