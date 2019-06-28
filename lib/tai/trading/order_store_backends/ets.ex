defmodule Tai.Trading.OrderStoreBackends.ETS do
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
    :ets.insert(name, record)
  end

  @doc """
  Update an existing order in the ETS table
  """
  def update(client_id, required, attrs, state) when is_list(required) do
    with {:ok, old_order} <- find_by_client_id(client_id, state.name) do
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

  def update(client_id, required, attrs, state), do: update(client_id, [required], attrs, state)

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
