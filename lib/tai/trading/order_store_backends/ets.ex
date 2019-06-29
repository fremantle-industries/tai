defmodule Tai.Trading.OrderStoreBackends.ETS do
  alias Tai.Trading.OrderStore.Action

  @type order :: Tai.Trading.Order.t()
  @type client_id :: Tai.Trading.Order.client_id()
  @type name :: atom

  def create(name) do
    :ets.new(name, [:set, :protected, :named_table])
    :ok
  end

  @doc """
  Insert an order into the ETS table
  """
  @spec insert(order, name) :: :ok
  def insert(order, name) do
    record = {order.client_id, order}
    true = :ets.insert(name, record)
    :ok
  end

  @doc """
  Update an existing order in the ETS table
  """
  def update(action, state) do
    with required <- action |> Action.required() |> List.wrap(),
         attrs <- Action.attrs(action),
         {:ok, old_order} <- find_by_client_id(action.client_id, state.name) do
      if Enum.member?(required, old_order.status) do
        updated_order = old_order |> Map.merge(attrs)
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
  @spec all(name) :: [] | [order]
  def all(name) do
    name
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, order} -> order end)
  end

  @doc """
  Return the order from the ETS table that matches the given client_id
  """
  @spec find_by_client_id(client_id, name) :: {:ok, order} | {:error, :not_found}
  def find_by_client_id(client_id, name) do
    with [{_, order}] <- :ets.lookup(name, client_id) do
      {:ok, order}
    else
      [] -> {:error, :not_found}
    end
  end

  defp format_required([required | []]), do: required
  defp format_required(required), do: required
end
