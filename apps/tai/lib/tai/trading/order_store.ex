defmodule Tai.Trading.OrderStore do
  @moduledoc """
  ETS backed store for the local state of orders
  """

  use GenServer
  alias Tai.Trading.{Order, OrderSubmissions}

  @type submission :: OrderSubmissions.Factory.submission()
  @type order :: Order.t()
  @type client_id :: Order.client_id()
  @type store_id :: atom

  @default_id :default
  @default_backend Tai.Trading.OrderStore.Backends.ETS

  defmodule State do
    @type t :: %State{id: atom, name: atom, backend: module}
    defstruct ~w(id name backend)a
  end

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    backend = Keyword.get(args, :backend, @default_backend)
    name = :"#{__MODULE__}_#{id}"
    state = %State{id: id, name: name, backend: backend}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state, {:continue, :init}}

  def handle_continue(:init, state) do
    :ok = state.backend.create(state.name)
    {:noreply, state}
  end

  def handle_call({:enqueue, submission}, _from, state) do
    order = OrderSubmissions.Factory.build!(submission)
    response = state.backend.insert(order, state.name)
    {:reply, response, state}
  end

  def handle_call({:update, action}, _from, state) do
    response = state.backend.update(action, state.name)
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
  Update the state of the order from the actions params
  """
  @spec update(action :: term) ::
          {:ok, {old :: order, updated :: order}}
          | {:error, :not_found | {:invalid_status, current :: atom, required :: term}}
  def update(action, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:update, action})
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

  @spec to_name(store_id) :: atom
  def to_name(store_id), do: :"#{__MODULE__}_#{store_id}"
end
