defmodule Tai.Trading.OrderStoreBackends.ETS do
  alias Tai.Trading.OrderStore.Action

  @type order :: Tai.Trading.Order.t()
  @type client_id :: Tai.Trading.Order.client_id()
  @type table_name :: atom

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
    record = {order.client_id, order}
    true = :ets.insert(table_name, record)
    {:ok, order}
  end

  @doc """
  Update an existing order in the ETS table
  """
  def update(action, state) do
    with required <- action |> Action.required() |> List.wrap(),
         attrs <- Action.attrs(action),
         {:ok, old_order} <- find_by_client_id(action.client_id, state.name) do
      if Enum.member?(required, old_order.status) do
        updated_order = old_order |> Map.merge(attrs) |> Map.put(:updated_at, Timex.now())
        insert(updated_order, state.name)
        {:ok, {old_order, updated_order}}
      else
        reason = {:invalid_status, old_order.status, required |> format_required}
        {:error, reason}
      end
    end
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

  defp format_required([required | []]), do: required
  defp format_required(required), do: required
end
