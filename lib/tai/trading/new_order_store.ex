defmodule Tai.Trading.NewOrderStore do
  @moduledoc """
  In memory store for the local state of orders
  """

  use GenServer
  alias Tai.Trading

  @type order :: Trading.Order.t()
  @type order_status :: Trading.Order.status()
  @type submission :: Trading.BuildOrderFromSubmission.submission()

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    :ok = GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  def init(state), do: {:ok, state}

  def handle_call(:create_ets_table, _from, state) do
    create_ets_table()
    {:reply, :ok, state}
  end

  def handle_call({:add, submission}, _from, state) do
    order = Trading.BuildOrderFromSubmission.build!(submission)
    record = {order.client_id, order}
    :ets.insert(__MODULE__, record)
    response = {:ok, order}
    {:reply, response, state}
  end

  @spec add(submission) :: {:ok, order} | no_return
  def add(submission) do
    GenServer.call(__MODULE__, {:add, submission})
  end

  @spec find_by_client_id(String.t()) :: {:ok, order} | {:error, :not_found}
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

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
