defmodule Tai.Advisors.Store.Backends.ETS do
  @type instance :: Tai.Advisors.Instance.t()
  @type table_name :: atom

  @doc """
  Create the ETS table that will store advisor instances
  """
  @spec create(table_name) :: :ok
  def create(table_name) do
    :ets.new(table_name, [:set, :protected, :named_table])
    :ok
  end

  @doc """
  Upsert an instance into the ETS table
  """
  @spec upsert(instance, table_name) :: {:ok, instance}
  def upsert(instance, table_name) do
    record = {{instance.group_id, instance.advisor_id}, instance}
    true = :ets.insert(table_name, record)
    {:ok, instance}
  end

  @doc """
  Return a list of all instances currently stored in the ETS table
  """
  @spec all(table_name) :: [instance]
  def all(table_name) do
    table_name
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.map(fn {_, instance} -> instance end)
  end
end
