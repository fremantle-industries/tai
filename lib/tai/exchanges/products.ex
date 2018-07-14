defmodule Tai.Exchanges.Products do
  use GenServer

  @type product :: Tai.Exchanges.Product.t()

  @table_name :products

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
    record = {{product.exchange_id, product.symbol}, product}
    :ets.insert(@table_name, record)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete(@table_name)
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

  @spec find({atom, atom}) :: {:ok, product} | {:error, :not_found}
  def find(key) do
    with [[%Tai.Exchanges.Product{} = product]] <- :ets.match(@table_name, {key, :"$1"}) do
      {:ok, product}
    else
      [] -> {:error, :not_found}
    end
  end

  @spec clear :: :ok
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  @spec all :: [product]
  def all do
    @table_name
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {{_, _}, product} -> product end)
  end

  defp create_ets_table do
    :ets.new(@table_name, [:set, :protected, :named_table])
  end
end
