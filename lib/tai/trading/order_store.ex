defmodule Tai.Trading.OrderStore do
  @moduledoc """
  ETS backed store for the local state of orders
  """

  use GenServer
  alias Tai.Trading.{Order, OrderSubmissions}

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type client_id :: Order.client_id()
  @type venue_order_id :: Order.venue_order_id()
  @type passive_fills_required ::
          :open | :pending_amend | :pending_cancel | :amend_error | :cancel_error
  @type passive_cancel_required ::
          :open
          | :expired
          | :filled
          | :pending_amend
          | :amend
          | :amend_error
          | :pending_cancel

  @default_id :default
  @default_backend Tai.Trading.OrderStoreBackends.ETS

  defmodule State do
    @type t :: %State{id: atom, name: atom, backend: atom}
    defstruct ~w(id name backend)a
  end

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    backend = Keyword.get(args, :backend, @default_backend)
    name = :"#{__MODULE__}_#{id}"
    state = %State{id: id, name: name, backend: backend}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state) do
    {:ok, state, {:continue, :init}}
  end

  def handle_continue(:init, state) do
    :ok = state.backend.create(state.name)
    {:noreply, state}
  end

  def handle_call({:enqueue, submission}, _from, state) do
    order = OrderSubmissions.Factory.build!(submission)
    state.backend.insert(order, state.name)
    response = {:ok, order}
    {:reply, response, state}
  end

  @zero Decimal.new(0)

  @skip_required :enqueued
  def handle_call({:skip, client_id}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @skip_required,
        %{
          status: :skip,
          leaves_qty: @zero
        },
        state
      )

    {:reply, response, state}
  end

  @accept_create_required :enqueued
  def handle_call(
        {:accept_create, client_id, venue_order_id, last_received_at, last_venue_timestamp},
        _from,
        state
      ) do
    response =
      state.backend.update(
        client_id,
        @accept_create_required,
        %{
          status: :create_accepted,
          venue_order_id: venue_order_id,
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

    {:reply, response, state}
  end

  @open_required [:enqueued, :create_accepted]
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
    qty = Decimal.add(cumulative_qty, leaves_qty)

    response =
      state.backend.update(
        client_id,
        @open_required,
        %{
          status: :open,
          venue_order_id: venue_order_id,
          avg_price: avg_price,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
          qty: qty,
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

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
      state.backend.update(
        client_id,
        @fill_required,
        %{
          status: :filled,
          venue_order_id: venue_order_id,
          avg_price: avg_price,
          cumulative_qty: cumulative_qty,
          leaves_qty: Decimal.new(0),
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

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
      state.backend.update(
        client_id,
        @expire_required,
        %{
          status: :expired,
          venue_order_id: venue_order_id,
          avg_price: avg_price,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

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
      state.backend.update(
        client_id,
        @reject_required,
        %{
          status: :rejected,
          venue_order_id: venue_order_id,
          leaves_qty: Decimal.new(0),
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

    {:reply, response, state}
  end

  @create_error_required :enqueued
  def handle_call({:create_error, client_id, error_reason, last_received_at}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @create_error_required,
        %{
          status: :create_error,
          error_reason: error_reason,
          leaves_qty: @zero,
          last_received_at: last_received_at
        },
        state
      )

    {:reply, response, state}
  end

  @pend_amend_required [:open, :amend_error]
  def handle_call({:pend_amend, client_id, updated_at}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @pend_amend_required,
        %{
          status: :pending_amend,
          updated_at: updated_at,
          error_reason: nil
        },
        state
      )

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
      state.backend.update(
        client_id,
        @amend_required,
        %{
          status: :open,
          price: price,
          leaves_qty: leaves_qty,
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

    {:reply, response, state}
  end

  @amend_error_required :pending_amend
  def handle_call({:amend_error, client_id, reason, last_received_at}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @amend_error_required,
        %{
          status: :amend_error,
          error_reason: reason,
          last_received_at: last_received_at
        },
        state
      )

    {:reply, response, state}
  end

  @pend_cancel_required :open
  def handle_call({:pend_cancel, client_id, updated_at}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @pend_cancel_required,
        %{
          status: :pending_cancel,
          updated_at: updated_at
        },
        state
      )

    {:reply, response, state}
  end

  @accept_cancel_required :pending_cancel
  def handle_call({:accept_cancel, client_id, last_venue_timestamp}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @accept_cancel_required,
        %{
          status: :cancel_accepted,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

    {:reply, response, state}
  end

  @cancel_required :pending_cancel
  def handle_call({:cancel, client_id, last_venue_timestamp}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @cancel_required,
        %{
          status: :canceled,
          last_venue_timestamp: last_venue_timestamp,
          leaves_qty: Decimal.new(0)
        },
        state
      )

    {:reply, response, state}
  end

  @cancel_error_required :pending_cancel
  def handle_call({:cancel_error, client_id, reason, last_received_at}, _from, state) do
    response =
      state.backend.update(
        client_id,
        @cancel_error_required,
        %{
          status: :cancel_error,
          error_reason: reason,
          last_received_at: last_received_at
        },
        state
      )

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
      state.backend.update(
        client_id,
        @passive_fills_required,
        %{
          status: :filled,
          cumulative_qty: cumulative_qty,
          leaves_qty: Decimal.new(0),
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

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
      state.backend.update(
        client_id,
        @passive_fills_required,
        %{
          status: :open,
          avg_price: avg_price,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

    {:reply, response, state}
  end

  @passive_cancel_required [
    :open,
    :expired,
    :filled,
    :pending_amend,
    :amend,
    :amend_error,
    :pending_cancel,
    :cancel_accepted
  ]
  def handle_call(
        {:passive_cancel, client_id, last_received_at, last_venue_timestamp},
        _from,
        state
      ) do
    response =
      state.backend.update(
        client_id,
        @passive_cancel_required,
        %{
          status: :canceled,
          leaves_qty: Decimal.new(0),
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        },
        state
      )

    {:reply, response, state}
  end

  def handle_call(:all, _from, state) do
    response = state.backend.all(state.name)
    {:reply, response, state}
  end

  def handle_call({:find_by_client_id, client_id}, _from, state) do
    response = state.backend.find_by_client_id(client_id, state.name)
    {:reply, response, state}
  end

  @doc """
  Enqueue an order from the submission by adding it into the backend
  """
  @spec enqueue(submission) :: {:ok, order} | no_return
  def enqueue(submission, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:enqueue, submission})
  end

  @doc """
  Bypass sending the order to the venue
  """
  @spec skip(client_id) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def skip(client_id, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:skip, client_id})
  end

  @doc """
  The create request has been accepted by the venue. The result of the
  created order is received in the stream.
  """
  @spec accept_create(client_id, venue_order_id, DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def accept_create(
        client_id,
        venue_order_id,
        last_received_at,
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :accept_create,
      client_id,
      venue_order_id,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  The order has been created on the venue and is passively sitting in
  the order book waiting to be filled
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
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :open,
      client_id,
      venue_order_id,
      avg_price,
      cumulative_qty,
      leaves_qty,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  The order was fully filled and removed from the order book
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
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :fill,
      client_id,
      venue_order_id,
      avg_price,
      cumulative_qty,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  The order was not filled or partially filled and removed from the order book
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
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :expire,
      client_id,
      venue_order_id,
      avg_price,
      cumulative_qty,
      leaves_qty,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  The order was not accepted by the venue. It most likely didn't pass validation on the venue.
  """
  @spec reject(client_id, venue_order_id, DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def reject(
        client_id,
        venue_order_id,
        last_received_at,
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :reject,
      client_id,
      venue_order_id,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  There was an error creating the order on the venue
  """
  @spec create_error(client_id, term, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :enqueued}}
  def create_error(client_id, error_reason, last_received_at, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:create_error, client_id, error_reason, last_received_at})
  end

  @doc """
  The order is going to be sent to the venue to be amended
  """
  @spec pend_amend(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             :not_found | {:invalid_status, current :: atom, required :: :open | :amend_error}}
  def pend_amend(client_id, updated_at, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:pend_amend, client_id, updated_at})
  end

  @doc """
  The order was successfully amended on the venue
  """
  @spec amend(client_id, Decimal.t(), Decimal.t(), DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_amend}}
  def amend(
        client_id,
        price,
        leaves_qty,
        last_received_at,
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :amend,
      client_id,
      price,
      leaves_qty,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  There was an error amending the order on the venue
  """
  @spec amend_error(client_id, term, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_amend}}
  def amend_error(client_id, reason, last_received_at, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:amend_error, client_id, reason, last_received_at})
  end

  @doc """
  The order is going to be sent to the venue to be canceled
  """
  @spec pend_cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :open}}
  def pend_cancel(client_id, updated_at, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:pend_cancel, client_id, updated_at})
  end

  @doc """
  The cancel request has been accepted by the venue. The result of the canceled
  order is received in the stream.
  """
  @spec accept_cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def accept_cancel(client_id, last_venue_timestamp, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:accept_cancel, client_id, last_venue_timestamp})
  end

  @doc """
  The order was successfully canceled on the venue
  """
  @spec cancel(client_id, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def cancel(client_id, last_venue_timestamp, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({
      :cancel,
      client_id,
      last_venue_timestamp
    })
  end

  @doc """
  There was an error canceling the order on the venue
  """
  @spec cancel_error(client_id, term, DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: :pending_cancel}}
  def cancel_error(client_id, reason, last_received_at, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({
      :cancel_error,
      client_id,
      reason,
      last_received_at
    })
  end

  @doc """
  An open order has been fully filled
  """
  @spec passive_fill(client_id, Decimal.t(), DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, passive_fills_required}}
  def passive_fill(
        client_id,
        cumulative_qty,
        last_received_at,
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :passive_fill,
      client_id,
      cumulative_qty,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  An open order has been partially filled
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
        last_venue_timestamp,
        store_id \\ @default_id
      ) do
    store_id
    |> to_name
    |> GenServer.call({
      :passive_partial_fill,
      client_id,
      avg_price,
      cumulative_qty,
      leaves_qty,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  An open order has been successfully canceled
  """
  @spec passive_cancel(client_id, DateTime.t(), DateTime.t()) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             :not_found
             | {:invalid_status, current :: atom, passive_cancel_required}}
  def passive_cancel(client_id, last_received_at, last_venue_timestamp, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({
      :passive_cancel,
      client_id,
      last_received_at,
      last_venue_timestamp
    })
  end

  @doc """
  Return a list of all orders currently stored in the backend
  """
  @spec all :: [] | [order]
  def all(store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call(:all)
  end

  @doc """
  Return the number of orders currently stored in the backend
  """
  @spec count :: non_neg_integer
  def count(store_id \\ @default_id), do: store_id |> all() |> Enum.count()

  @doc """
  Return the order from the backend that matches the given client_id
  """
  @spec find_by_client_id(client_id) :: {:ok, order} | {:error, :not_found}
  def find_by_client_id(client_id, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:find_by_client_id, client_id})
  end

  defp to_name(store_id), do: :"#{__MODULE__}_#{store_id}"
end
