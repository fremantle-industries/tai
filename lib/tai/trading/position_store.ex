defmodule Tai.Trading.PositionStore do
  @moduledoc """
  ETS backed store for the local state of margin positions
  """

  use GenServer
  alias Tai.Trading

  @type position :: Trading.Position.t()

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

  def handle_call({:add, position}, _from, state) do
    insert(position)
    response = {:ok, position}
    {:reply, response, state}
  end

  @spec add(position) :: {:ok, position} | no_return
  def add(position), do: GenServer.call(__MODULE__, {:add, position})

  @spec all :: [] | [position]
  def all do
    __MODULE__
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, position} -> position end)
  end

  defp insert(position) do
    key = {position.venue_id, position.account_id, position.product_symbol}
    record = {key, position}
    :ets.insert(__MODULE__, record)
  end
end
