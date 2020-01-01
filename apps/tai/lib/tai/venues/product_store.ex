defmodule Tai.Venues.ProductStore do
  use GenServer

  @type product :: Tai.Venues.Product.t()
  @type symbol :: Tai.Venues.Product.symbol()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type venue_id :: Tai.Venue.id()

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:create_ets_table, _from, state) do
    create_ets_table()
    {:reply, :ok, state}
  end

  def handle_call({:upsert, product}, _from, state) do
    record = {{product.venue_id, product.symbol, product.venue_symbol}, product}
    :ets.insert(__MODULE__, record)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete(__MODULE__)
    create_ets_table()
    {:reply, :ok, state}
  end

  @spec upsert(product) :: :ok
  def upsert(product) do
    GenServer.call(__MODULE__, {:upsert, product})
  end

  @spec count :: number
  def count do
    all()
    |> Enum.count()
  end

  @spec find({venue_id, symbol}) :: {:ok, product} | {:error, :not_found}
  def find({venue_id, symbol}) do
    with [[%Tai.Venues.Product{} = product]] <-
           :ets.match(__MODULE__, {{venue_id, symbol, :_}, :"$1"}) do
      {:ok, product}
    else
      [] -> {:error, :not_found}
    end
  end

  @spec find_by_venue_symbol({venue_id, venue_symbol}) :: {:ok, product} | {:error, :not_found}
  def find_by_venue_symbol({venue_id, venue_symbol}) do
    with [[%Tai.Venues.Product{} = product]] <-
           :ets.match(__MODULE__, {{venue_id, :_, venue_symbol}, :"$1"}) do
      {:ok, product}
    else
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Return a list of products that match the filters
  """
  @spec where(filters :: [...]) :: [product]
  def where(filters) do
    all()
    |> Enum.filter(fn product ->
      filters
      |> Keyword.keys()
      |> Enum.all?(&(Map.get(product, &1) == Keyword.get(filters, &1)))
    end)
  end

  @spec clear :: :ok
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  @spec all :: [product]
  def all do
    __MODULE__
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
