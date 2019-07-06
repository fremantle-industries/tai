defmodule Tai.Advisors.Store do
  @moduledoc """
  ETS backed store for the local state of advisors
  """

  use GenServer

  @type store_id :: atom
  @type instance :: Tai.Advisors.Instance.t()

  @default_store_id :default
  @default_backend Tai.Advisors.Store.Backends.ETS

  defmodule State do
    @type t :: %State{id: atom, name: atom, backend: atom}
    defstruct ~w(id name backend)a
  end

  def start_link(args) do
    store_id = Keyword.get(args, :id, @default_store_id)
    backend = Keyword.get(args, :backend, @default_backend)
    name = :"#{__MODULE__}_#{store_id}"
    state = %State{id: store_id, name: name, backend: backend}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state, {:continue, :init}}

  def handle_continue(:init, state) do
    :ok = state.backend.create(state.name)
    {:noreply, state}
  end

  def handle_call({:upsert, instance}, _from, state) do
    response = state.backend.upsert(instance, state.name)
    {:reply, response, state}
  end

  def handle_call(:all, _from, state) do
    response = state.backend.all(state.name)
    {:reply, response, state}
  end

  def upsert(instance, store_id \\ @default_store_id) do
    store_id
    |> to_name
    |> GenServer.call({:upsert, instance})
  end

  @spec all() :: [instance]
  def all(store_id \\ @default_store_id) do
    store_id
    |> to_name
    |> GenServer.call(:all)
  end

  @spec to_name(store_id) :: atom
  def to_name(store_id), do: :"#{__MODULE__}_#{store_id}"

  @spec default_store_id :: store_id
  def default_store_id, do: @default_store_id
end
