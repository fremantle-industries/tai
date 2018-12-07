defmodule Tai.Trading.OrderStore do
  @moduledoc """
  In memory store for the local state of orders
  """

  use GenServer
  alias Tai.Trading

  @type order :: Trading.Order.t()
  @type order_status :: Trading.Order.status()
  @type submission ::
          Trading.OrderSubmissions.BuyLimitGtc.t()
          | Trading.OrderSubmissions.SellLimitGtc.t()
          | Trading.OrderSubmissions.BuyLimitFok.t()
          | Trading.OrderSubmissions.SellLimitFok.t()
          | Trading.OrderSubmissions.BuyLimitIoc.t()
          | Trading.OrderSubmissions.SellLimitIoc.t()

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def handle_call({:add, submission}, _from, state) do
    order = build_order(submission)
    new_state = Map.put(state, order.client_id, order)
    response = {:ok, order}

    {:reply, response, new_state}
  end

  def handle_call({:find, client_id}, _from, state) do
    result =
      state
      |> Map.fetch(client_id)
      |> case do
        {:ok, order} -> {:ok, order}
        :error -> {:error, :not_found}
      end

    {:reply, result, state}
  end

  def handle_call({:find_by_and_update, filters, update_attrs}, _from, state) do
    with [current_order] <- state |> filter(filters) |> Map.values(),
         updated_order <-
           Trading.OrderStore.AttributeWhitelist.apply(
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

  @spec add(submission) :: {:ok, order}
  def add(submission) do
    GenServer.call(__MODULE__, {:add, submission})
  end

  @spec find(client_id :: String.t()) :: {:ok, order} | {:error, :not_found}
  def find(client_id) do
    GenServer.call(__MODULE__, {:find, client_id})
  end

  @spec find_by_and_update(list, list) ::
          {:ok, term} | {:error, :not_found | :multiple_orders_found}
  def find_by_and_update(query, update_attrs) do
    GenServer.call(__MODULE__, {:find_by_and_update, query, update_attrs})
  end

  @spec all :: [order]
  def all do
    GenServer.call(__MODULE__, :all)
  end

  @spec where(list) :: [order]
  def where([_head | _tail] = filters) do
    GenServer.call(__MODULE__, {:where, filters})
  end

  @spec count :: pos_integer
  @spec count(status: order_status) :: pos_integer
  def count, do: GenServer.call(__MODULE__, :count)
  def count(status: status), do: GenServer.call(__MODULE__, {:count, status: status})

  defp build_order(submission) do
    %Trading.Order{
      client_id: UUID.uuid4(),
      exchange_id: submission.venue_id,
      account_id: submission.account_id,
      symbol: submission.product_symbol,
      side: submission |> side,
      type: submission |> type,
      price: submission.price |> Decimal.abs(),
      size: submission.qty |> Decimal.abs(),
      time_in_force: submission |> time_in_force,
      post_only: submission |> post_only,
      status: :enqueued,
      enqueued_at: Timex.now(),
      order_updated_callback: submission.order_updated_callback
    }
  end

  defp type(%Trading.OrderSubmissions.BuyLimitGtc{}), do: :limit
  defp type(%Trading.OrderSubmissions.BuyLimitFok{}), do: :limit
  defp type(%Trading.OrderSubmissions.BuyLimitIoc{}), do: :limit
  defp type(%Trading.OrderSubmissions.SellLimitGtc{}), do: :limit
  defp type(%Trading.OrderSubmissions.SellLimitFok{}), do: :limit
  defp type(%Trading.OrderSubmissions.SellLimitIoc{}), do: :limit

  defp side(%Trading.OrderSubmissions.BuyLimitGtc{}), do: :buy
  defp side(%Trading.OrderSubmissions.BuyLimitFok{}), do: :buy
  defp side(%Trading.OrderSubmissions.BuyLimitIoc{}), do: :buy
  defp side(%Trading.OrderSubmissions.SellLimitGtc{}), do: :sell
  defp side(%Trading.OrderSubmissions.SellLimitFok{}), do: :sell
  defp side(%Trading.OrderSubmissions.SellLimitIoc{}), do: :sell

  defp time_in_force(%Trading.OrderSubmissions.BuyLimitGtc{}), do: :gtc
  defp time_in_force(%Trading.OrderSubmissions.BuyLimitFok{}), do: :fok
  defp time_in_force(%Trading.OrderSubmissions.BuyLimitIoc{}), do: :ioc
  defp time_in_force(%Trading.OrderSubmissions.SellLimitGtc{}), do: :gtc
  defp time_in_force(%Trading.OrderSubmissions.SellLimitFok{}), do: :fok
  defp time_in_force(%Trading.OrderSubmissions.SellLimitIoc{}), do: :ioc

  defp post_only(%Trading.OrderSubmissions.BuyLimitGtc{post_only: post_only}), do: post_only
  defp post_only(%Trading.OrderSubmissions.BuyLimitFok{}), do: false
  defp post_only(%Trading.OrderSubmissions.BuyLimitIoc{}), do: false
  defp post_only(%Trading.OrderSubmissions.SellLimitGtc{post_only: post_only}), do: post_only
  defp post_only(%Trading.OrderSubmissions.SellLimitFok{}), do: false
  defp post_only(%Trading.OrderSubmissions.SellLimitIoc{}), do: false

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
