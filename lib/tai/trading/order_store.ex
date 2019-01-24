defmodule Tai.Trading.OrderStore do
  @moduledoc """
  ETS backed store for the local state of orders
  """

  use GenServer
  alias Tai.Trading

  @type client_id :: String.t()
  @type venue_order_id :: Trading.Order.venue_order_id()
  @type order :: Trading.Order.t()
  @type order_status :: Trading.Order.status()
  @type submission :: Trading.BuildOrderFromSubmission.submission()
  @type passive_fills_required ::
          :open | :pending_amend | :pending_cancel | :amend_error | :cancel_error

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    :ok = GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  def init(state), do: {:ok, state}

  def handle_call(:create_ets_table, _from, state) do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
    {:reply, :ok, state}
  end

  def handle_call({:add, submission}, _from, state) do
    order = Trading.BuildOrderFromSubmission.build!(submission)
    insert(order)
    response = {:ok, order}
    {:reply, response, state}
  end

  @zero Decimal.new(0)

  @skip_required :enqueued
  def handle_call({:skip, client_id}, _from, state) do
    response =
      update(client_id, @skip_required, %{
        status: :skip,
        leaves_qty: @zero
      })

    {:reply, response, state}
  end

  @create_error_required :enqueued
  def handle_call({:create_error, client_id, error_reason}, _from, state) do
    response =
      update(client_id, @create_error_required, %{
        status: :create_error,
        error_reason: error_reason,
        leaves_qty: @zero
      })

    {:reply, response, state}
  end

  @expire_required :enqueued
  def handle_call(
        {
          :expire,
          client_id,
          venue_order_id,
          venue_created_at,
          avg_price,
          cumulative_qty,
          leaves_qty
        },
        _from,
        state
      ) do
    response =
      update(client_id, @expire_required, %{
        status: :expired,
        venue_order_id: venue_order_id,
        venue_created_at: venue_created_at,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty
      })

    {:reply, response, state}
  end

  @open_required :enqueued
  def handle_call(
        {
          :open,
          client_id,
          venue_order_id,
          venue_created_at,
          avg_price,
          cumulative_qty,
          leaves_qty
        },
        _from,
        state
      ) do
    response =
      update(client_id, @open_required, %{
        status: :open,
        venue_order_id: venue_order_id,
        venue_created_at: venue_created_at,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty
      })

    {:reply, response, state}
  end

  @amend_required :pending_amend
  def handle_call(
        {
          :amend,
          client_id,
          venue_updated_at,
          price,
          leaves_qty
        },
        _from,
        state
      ) do
    response =
      update(client_id, @amend_required, %{
        status: :open,
        venue_updated_at: venue_updated_at,
        price: price,
        leaves_qty: leaves_qty
      })

    {:reply, response, state}
  end

  @pend_amend_required [:open, :amend_error]
  def handle_call({:pend_amend, client_id, updated_at}, _from, state) do
    response =
      update(client_id, @pend_amend_required, %{
        status: :pending_amend,
        updated_at: updated_at,
        error_reason: nil
      })

    {:reply, response, state}
  end

  @fill_required :enqueued
  def handle_call(
        {
          :fill,
          client_id,
          venue_order_id,
          venue_created_at,
          avg_price,
          cumulative_qty
        },
        _from,
        state
      ) do
    response =
      update(client_id, @fill_required, %{
        status: :filled,
        venue_order_id: venue_order_id,
        venue_created_at: venue_created_at,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: Decimal.new(0)
      })

    {:reply, response, state}
  end

  @passive_fills_required [:open, :pending_amend, :pending_cancel, :amend_error, :cancel_error]
  def handle_call(
        {
          :passive_fill,
          client_id,
          venue_updated_at,
          avg_price,
          cumulative_qty
        },
        _from,
        state
      ) do
    response =
      update(client_id, @passive_fills_required, %{
        status: :filled,
        venue_updated_at: venue_updated_at,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: Decimal.new(0)
      })

    {:reply, response, state}
  end

  def handle_call(
        {
          :passive_partial_fill,
          client_id,
          venue_updated_at,
          avg_price,
          cumulative_qty,
          leaves_qty
        },
        _from,
        state
      ) do
    response =
      update(client_id, @passive_fills_required, %{
        status: :open,
        venue_updated_at: venue_updated_at,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty
      })

    {:reply, response, state}
  end

  @amend_error_required :pending_amend
  def handle_call({:amend_error, client_id, reason}, _from, state) do
    response =
      update(client_id, @amend_error_required, %{
        status: :amend_error,
        error_reason: reason
      })

    {:reply, response, state}
  end

  @pend_cancel_required :open
  def handle_call({:pend_cancel, client_id, updated_at}, _from, state) do
    response =
      update(client_id, @pend_cancel_required, %{
        status: :pending_cancel,
        updated_at: updated_at
      })

    {:reply, response, state}
  end

  @cancel_error_required :pending_cancel
  def handle_call({:cancel_error, client_id, reason}, _from, state) do
    response =
      update(client_id, @cancel_error_required, %{
        status: :cancel_error,
        error_reason: reason
      })

    {:reply, response, state}
  end

  @passive_cancel_required [
    :enqueued,
    :open,
    :expired,
    :filled,
    :pending_cancel,
    :pending_amend,
    :cancel,
    :amend
  ]
  def handle_call({:passive_cancel, client_id, venue_updated_at}, _from, state) do
    response =
      update(client_id, @passive_cancel_required, %{
        status: :canceled,
        venue_updated_at: venue_updated_at,
        leaves_qty: Decimal.new(0)
      })

    {:reply, response, state}
  end

  @cancel_required :pending_cancel
  def handle_call({:cancel, client_id, venue_updated_at}, _from, state) do
    response =
      update(client_id, @cancel_required, %{
        status: :canceled,
        venue_updated_at: venue_updated_at,
        leaves_qty: Decimal.new(0)
      })

    {:reply, response, state}
  end

  @spec add(submission) :: {:ok, order} | no_return
  def add(submission), do: GenServer.call(__MODULE__, {:add, submission})

  @spec skip(client_id) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def skip(client_id), do: GenServer.call(__MODULE__, {:skip, client_id})

  @spec create_error(client_id, term) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def create_error(client_id, error_reason),
    do: GenServer.call(__MODULE__, {:create_error, client_id, error_reason})

  @spec expire(client_id, venue_order_id, DateTime.t(), Decimal.t(), Decimal.t(), Decimal.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def expire(
        client_id,
        venue_order_id,
        venue_created_at,
        avg_price,
        cumulative_qty,
        leaves_qty
      ) do
    GenServer.call(
      __MODULE__,
      {
        :expire,
        client_id,
        venue_order_id,
        venue_created_at,
        avg_price,
        cumulative_qty,
        leaves_qty
      }
    )
  end

  @spec fill(client_id, venue_order_id, DateTime.t(), Decimal.t(), Decimal.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def fill(
        client_id,
        venue_order_id,
        venue_created_at,
        avg_price,
        cumulative_qty
      ) do
    GenServer.call(
      __MODULE__,
      {
        :fill,
        client_id,
        venue_order_id,
        venue_created_at,
        avg_price,
        cumulative_qty
      }
    )
  end

  @spec passive_fill(client_id, DateTime.t(), Decimal.t(), Decimal.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, passive_fills_required}}
  def passive_fill(
        client_id,
        venue_updated_at,
        avg_price,
        cumulative_qty
      ) do
    GenServer.call(
      __MODULE__,
      {
        :passive_fill,
        client_id,
        venue_updated_at,
        avg_price,
        cumulative_qty
      }
    )
  end

  @spec passive_partial_fill(client_id, DateTime.t(), Decimal.t(), Decimal.t(), Decimal.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, passive_fills_required}}
  def passive_partial_fill(
        client_id,
        venue_updated_at,
        avg_price,
        cumulative_qty,
        leaves_qty
      ) do
    GenServer.call(
      __MODULE__,
      {
        :passive_partial_fill,
        client_id,
        venue_updated_at,
        avg_price,
        cumulative_qty,
        leaves_qty
      }
    )
  end

  @spec open(client_id, venue_order_id, DateTime.t(), Decimal.t(), Decimal.t(), Decimal.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def open(
        client_id,
        venue_order_id,
        venue_created_at,
        avg_price,
        cumulative_qty,
        leaves_qty
      ) do
    GenServer.call(
      __MODULE__,
      {
        :open,
        client_id,
        venue_order_id,
        venue_created_at,
        avg_price,
        cumulative_qty,
        leaves_qty
      }
    )
  end

  @spec amend(client_id, DateTime.t(), Decimal.t(), Decimal.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_amend}}
  def amend(
        client_id,
        venue_updated_at,
        price,
        leaves_qty
      ) do
    GenServer.call(
      __MODULE__,
      {
        :amend,
        client_id,
        venue_updated_at,
        price,
        leaves_qty
      }
    )
  end

  @spec pend_amend(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             :not_found | {:invalid_status, current :: atom, required :: :open | :amend_error}}
  def pend_amend(client_id, updated_at),
    do: GenServer.call(__MODULE__, {:pend_amend, client_id, updated_at})

  @spec amend_error(client_id, term) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_amend}}
  def amend_error(client_id, reason),
    do: GenServer.call(__MODULE__, {:amend_error, client_id, reason})

  @spec pend_cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :open}}
  def pend_cancel(client_id, updated_at),
    do: GenServer.call(__MODULE__, {:pend_cancel, client_id, updated_at})

  @spec cancel_error(client_id, term) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def cancel_error(client_id, reason),
    do: GenServer.call(__MODULE__, {:cancel_error, client_id, reason})

  @type passive_cancel_required ::
          :enqueued
          | :open
          | :expired
          | :filled
          | :pending_cancel
          | :pending_amend
          | :cancel
          | :amend
  @spec passive_cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             :not_found
             | {:invalid_status, current :: atom, passive_cancel_required}}
  def passive_cancel(client_id, venue_updated_at),
    do: GenServer.call(__MODULE__, {:passive_cancel, client_id, venue_updated_at})

  @spec cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def cancel(client_id, venue_updated_at),
    do: GenServer.call(__MODULE__, {:cancel, client_id, venue_updated_at})

  @spec find_by_client_id(client_id) :: {:ok, order} | {:error, :not_found}
  def find_by_client_id(client_id) do
    with [{_, order}] <- :ets.lookup(__MODULE__, client_id) do
      {:ok, order}
    else
      [] -> {:error, :not_found}
    end
  end

  @spec all :: [] | [order]
  def all do
    __MODULE__
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, order} -> order end)
  end

  @spec count :: non_neg_integer
  def count, do: all() |> Enum.count()

  defp insert(order) do
    record = {order.client_id, order}
    :ets.insert(__MODULE__, record)
  end

  defp update(client_id, required, attrs) when is_list(required) do
    with {:ok, old_order} <- find_by_client_id(client_id) do
      if required |> Enum.member?(old_order.status) do
        updated_order = old_order |> Map.merge(attrs)
        insert(updated_order)
        {:ok, {old_order, updated_order}}
      else
        reason = {:invalid_status, old_order.status, required |> format_required}
        {:error, reason}
      end
    end
  end

  defp update(client_id, required, attrs), do: update(client_id, [required], attrs)

  defp format_required([required | []]), do: required
  defp format_required(required), do: required
end
