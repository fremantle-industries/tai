defmodule Tai.Venues.AccountStore do
  use GenServer

  @type account :: Tai.Venues.Account.t()

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  @spec upsert(account) :: :ok
  def upsert(account) do
    GenServer.call(__MODULE__, {:upsert, account})
  end

  @spec all :: [account]
  def all() do
    __MODULE__
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.reduce(
      [],
      fn {_, account}, acc -> [account | acc] end
    )
  end

  @spec where(filters :: [...]) :: [account]
  def where(filters) do
    all()
    |> Enum.reduce(
      [],
      fn account, acc ->
        matched_all_filters =
          filters
          |> Keyword.keys()
          |> Enum.all?(fn filter ->
            case filter do
              :venue_id ->
                account.venue_id == Keyword.get(filters, filter)

              :credential_id ->
                account.credential_id == Keyword.get(filters, filter)

              :asset ->
                account.asset == Keyword.get(filters, filter)

              _ ->
                Map.get(account, filter) == Keyword.get(filters, filter)
            end
          end)

        if matched_all_filters do
          [account | acc]
        else
          acc
        end
      end
    )
  end

  @spec find_by(filters :: [...]) :: {:ok, account} | {:error, :not_found}
  def find_by(filters) do
    with %Tai.Venues.Account{} = account <- filters |> where() |> List.first() do
      {:ok, account}
    else
      nil ->
        {:error, :not_found}
    end
  end

  def init(state), do: {:ok, state}

  def handle_call(:create_ets_table, _from, state) do
    create_ets_table()
    {:reply, :ok, state}
  end

  def handle_call({:upsert, account}, _from, state) do
    upsert_ets_table(account)
    {:reply, :ok, state}
  end

  defp upsert_ets_table(account) do
    record = {{account.venue_id, account.credential_id, account.asset, account.type}, account}
    :ets.insert(__MODULE__, record)
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
