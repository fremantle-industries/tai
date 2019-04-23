defmodule Tai.Trading.OrderStore do
  @moduledoc """
  ETS backed store for the local state of orders
  """

  use GenServer
  alias Tai.Trading.{Order, BuildOrderFromSubmission}

  @type submission :: BuildOrderFromSubmission.submission()
  @type order :: Order.t()
  @type client_id :: Order.client_id()
  @type venue_order_id :: Order.venue_order_id()
  @type passive_fills_required ::
          :open | :pending_amend | :pending_cancel | :amend_error | :cancel_error
  @type passive_cancel_required ::
          :open
          | :expired
          | :filled
          | :pending_cancel
          | :pending_amend
          | :canceled
          | :amend
          | :amend_error

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

  def handle_call({:enqueue, submission}, _from, state) do
    order = BuildOrderFromSubmission.build!(submission)
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
  def handle_call({:create_error, client_id, error_reason, last_received_at}, _from, state) do
    response =
      update(client_id, @create_error_required, %{
        status: :create_error,
        error_reason: error_reason,
        leaves_qty: @zero,
        last_received_at: last_received_at
      })

    {:reply, response, state}
  end

  @expire_required :enqueued
  def handle_call(
        {
          :expire,
          client_id,
          venue_order_id,
          avg_price,
          cumulative_qty,
          leaves_qty,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @expire_required, %{
        status: :expired,
        venue_order_id: venue_order_id,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  @open_required :enqueued
  def handle_call(
        {
          :open,
          client_id,
          venue_order_id,
          avg_price,
          cumulative_qty,
          leaves_qty,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @open_required, %{
        status: :open,
        venue_order_id: venue_order_id,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  @reject_required :enqueued
  def handle_call(
        {
          :reject,
          client_id,
          venue_order_id,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @reject_required, %{
        status: :rejected,
        venue_order_id: venue_order_id,
        leaves_qty: Decimal.new(0),
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  @amend_required :pending_amend
  def handle_call(
        {
          :amend,
          client_id,
          price,
          leaves_qty,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @amend_required, %{
        status: :open,
        price: price,
        leaves_qty: leaves_qty,
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
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
          avg_price,
          cumulative_qty,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @fill_required, %{
        status: :filled,
        venue_order_id: venue_order_id,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: Decimal.new(0),
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  @passive_fills_required [:open, :pending_amend, :pending_cancel, :amend_error, :cancel_error]
  def handle_call(
        {
          :passive_fill,
          client_id,
          cumulative_qty,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @passive_fills_required, %{
        status: :filled,
        cumulative_qty: cumulative_qty,
        leaves_qty: Decimal.new(0),
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  def handle_call(
        {
          :passive_partial_fill,
          client_id,
          avg_price,
          cumulative_qty,
          leaves_qty,
          last_received_at,
          last_venue_timestamp
        },
        _from,
        state
      ) do
    response =
      update(client_id, @passive_fills_required, %{
        status: :open,
        avg_price: avg_price,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  @amend_error_required :pending_amend
  def handle_call({:amend_error, client_id, reason, last_received_at}, _from, state) do
    response =
      update(client_id, @amend_error_required, %{
        status: :amend_error,
        error_reason: reason,
        last_received_at: last_received_at
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
  def handle_call({:cancel_error, client_id, reason, last_received_at}, _from, state) do
    response =
      update(client_id, @cancel_error_required, %{
        status: :cancel_error,
        error_reason: reason,
        last_received_at: last_received_at
      })

    {:reply, response, state}
  end

  @passive_cancel_required [
    :open,
    :expired,
    :filled,
    :pending_cancel,
    :pending_amend,
    :amend,
    :amend_error
  ]
  def handle_call(
        {:passive_cancel, client_id, last_received_at, last_venue_timestamp},
        _from,
        state
      ) do
    response =
      update(client_id, @passive_cancel_required, %{
        status: :canceled,
        leaves_qty: Decimal.new(0),
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      })

    {:reply, response, state}
  end

  @cancel_required :pending_cancel
  def handle_call({:cancel, client_id, last_venue_timestamp}, _from, state) do
    response =
      update(client_id, @cancel_required, %{
        status: :canceled,
        last_venue_timestamp: last_venue_timestamp,
        leaves_qty: Decimal.new(0)
      })

    {:reply, response, state}
  end

  @doc """
  Build an enqueued order from the submission and insert it into the ETS table
  """
  @deprecated "Use Tai.Trading.OrderStore.enqueue/1 instead."
  @spec add(submission) :: {:ok, order} | no_return
  def add(submission), do: enqueue(submission)

  @doc """
  Enqueue and order from the submission and insert it into the ETS table
  """
  @spec enqueue(submission) :: {:ok, order} | no_return
  def enqueue(submission), do: GenServer.call(__MODULE__, {:enqueue, submission})

  @doc """
  Change the ordertatus to skip when orders aren't sent to the venue
  """
  @spec skip(client_id) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def skip(client_id), do: GenServer.call(__MODULE__, {:skip, client_id})

  @doc """
  Change the order status to create_error when it failed on the venue
  """
  @spec create_error(client_id, term, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def create_error(client_id, error_reason, last_received_at),
    do: GenServer.call(__MODULE__, {:create_error, client_id, error_reason, last_received_at})

  @doc """
  Change the order status to expired 
  """
  @spec expire(
          client_id,
          venue_order_id,
          Decimal.t(),
          Decimal.t(),
          Decimal.t(),
          DateTime.t(),
          DateTime.t()
        ) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def expire(
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :expire,
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @doc """
  Update the cumulative_qty & price for a fully filled order
  """
  @spec fill(client_id, venue_order_id, Decimal.t(), Decimal.t(), DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def fill(
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :fill,
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @doc """
  Update the cumulative_qty & price for a fully filled passive order
  """
  @spec passive_fill(client_id, Decimal.t(), DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, passive_fills_required}}
  def passive_fill(
        client_id,
        cumulative_qty,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :passive_fill,
        client_id,
        cumulative_qty,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @doc """
  Update the cumulative_qty & price for a partially filled passive order
  """
  @spec passive_partial_fill(
          client_id,
          Decimal.t(),
          Decimal.t(),
          Decimal.t(),
          DateTime.t(),
          DateTime.t()
        ) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, passive_fills_required}}
  def passive_partial_fill(
        client_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :passive_partial_fill,
        client_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @doc """
  Change the order status to open after it was enqueued
  """
  @spec open(
          client_id,
          venue_order_id,
          Decimal.t(),
          Decimal.t(),
          Decimal.t(),
          DateTime.t(),
          DateTime.t()
        ) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def open(
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :open,
        client_id,
        venue_order_id,
        avg_price,
        cumulative_qty,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @spec reject(client_id, venue_order_id, DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def reject(
        client_id,
        venue_order_id,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :reject,
        client_id,
        venue_order_id,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @doc """
  Change the order status to open after an amend attempt
  """
  @spec amend(client_id, Decimal.t(), Decimal.t(), DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_amend}}
  def amend(
        client_id,
        price,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      ) do
    GenServer.call(
      __MODULE__,
      {
        :amend,
        client_id,
        price,
        leaves_qty,
        last_received_at,
        last_venue_timestamp
      }
    )
  end

  @doc """
  Change the order status to pending_amend
  """
  @spec pend_amend(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             :not_found | {:invalid_status, current :: atom, required :: :open | :amend_error}}
  def pend_amend(client_id, updated_at),
    do: GenServer.call(__MODULE__, {:pend_amend, client_id, updated_at})

  @doc """
  Change the order status to amend_error after an amend attempt
  """
  @spec amend_error(client_id, term, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_amend}}
  def amend_error(client_id, reason, last_received_at),
    do: GenServer.call(__MODULE__, {:amend_error, client_id, reason, last_received_at})

  @doc """
  Change the order status to pending_cancel
  """
  @spec pend_cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :open}}
  def pend_cancel(client_id, updated_at),
    do: GenServer.call(__MODULE__, {:pend_cancel, client_id, updated_at})

  @doc """
  Change the order status to cancel_error after a cancel attempt
  """
  @spec cancel_error(client_id, term, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def cancel_error(client_id, reason, last_received_at),
    do: GenServer.call(__MODULE__, {:cancel_error, client_id, reason, last_received_at})

  @doc """
  Change the order status to canceled from an external passive source
  """
  @spec passive_cancel(client_id, DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             :not_found
             | {:invalid_status, current :: atom, passive_cancel_required}}
  def passive_cancel(client_id, last_received_at, last_venue_timestamp),
    do:
      GenServer.call(
        __MODULE__,
        {:passive_cancel, client_id, last_received_at, last_venue_timestamp}
      )

  @doc """
  Change the order status to canceled after a cancel attempt
  """
  @spec cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def cancel(client_id, last_venue_timestamp),
    do: GenServer.call(__MODULE__, {:cancel, client_id, last_venue_timestamp})

  @doc """
  Return the order in the ETS table that matches the given client_id
  """
  @spec find_by_client_id(client_id) :: {:ok, order} | {:error, :not_found}
  def find_by_client_id(client_id) do
    with [{_, order}] <- :ets.lookup(__MODULE__, client_id) do
      {:ok, order}
    else
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Return a list of all orders currently stored in the ETS table
  """
  @spec all :: [] | [order]
  def all do
    __MODULE__
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, order} -> order end)
  end

  @doc """
  Return the count of all orders currently stored in the ETS table
  """
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
