defmodule Tai.Venues.FeeStore do
  use GenServer

  @type fee_info :: Tai.Venues.FeeInfo.t()

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

  def handle_call({:upsert, fee_info}, _from, state) do
    key = {fee_info.exchange_id, fee_info.account_id, fee_info.symbol}
    record = {key, fee_info}
    :ets.insert(__MODULE__, record)
    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete(__MODULE__)
    create_ets_table()
    {:reply, :ok, state}
  end

  @spec upsert(fee_info) :: :ok
  def upsert(%Tai.Venues.FeeInfo{} = fee_info) do
    GenServer.call(__MODULE__, {:upsert, fee_info})
  end

  @spec clear :: :ok
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  @spec find_by(exchange_id: atom, account_id: atom, symbol: atom) ::
          {:ok, fee_info} | {:error, :not_found}
  def find_by(exchange_id: exchange_id, account_id: account_id, symbol: symbol) do
    with key <- {exchange_id, account_id, symbol},
         [[%Tai.Venues.FeeInfo{} = fee_info]] <- :ets.match(__MODULE__, {key, :"$1"}) do
      {:ok, fee_info}
    else
      [] -> {:error, :not_found}
    end
  end

  @spec all :: []
  def all do
    __MODULE__
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {{_, _, _}, fee_info} -> fee_info end)
  end

  @spec count :: number
  def count do
    all()
    |> Enum.count()
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
