defmodule Tai.Orders.OrderStore.Backends.ETS do
  alias Tai.Orders.Order

  @type order :: Order.t()
  @type status :: Order.status()
  @type client_id :: Order.client_id()
  @type table_name :: atom
  @type transition :: term

  @spec create(table_name) :: :ok
  def create(table_name) do
    :ets.new(table_name, [:set, :protected, :named_table])
    :ok
  end

  @doc """
  Insert an order into the ETS table
  """
  @spec insert(order, table_name) :: {:ok, order}
  def insert(order, table_name) do
    true = upsert(order, table_name)
    {:ok, order}
  end

  @doc """
  Update an existing order in the ETS table
  """
  @spec update(transition, table_name) :: {:ok, order}
  def update(order, table_name) do
    true = upsert(order, table_name)
    {:ok, order}
  end

  @doc """
  Return a list of all orders currently stored in the ETS table
  """
  @spec all(table_name) :: [] | [order]
  def all(table_name) do
    table_name
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, order} -> order end)
  end

  @doc """
  Return the order from the ETS table that matches the given client_id
  """
  @spec find_by_client_id(client_id, table_name) :: {:ok, order} | {:error, :not_found}
  def find_by_client_id(client_id, table_name) do
    with [{_, order}] <- :ets.lookup(table_name, client_id) do
      {:ok, order}
    else
      [] -> {:error, :not_found}
    end
  end

  defp upsert(order, table_name) do
    record = {order.client_id, order}
    :ets.insert(table_name, record)
  end
end
