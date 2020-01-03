defmodule Tai.Venues.AccountStore do
  alias Tai.Venues.AccountStore
  use GenServer

  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type asset :: Tai.Venues.Account.asset()
  @type account :: Tai.Venues.Account.t()
  @type lock_request :: AccountStore.LockRequest.t()
  @type lock_result ::
          {:ok, Decimal.t()}
          | {:error,
             :not_found | :insufficient_balance | :min_greater_than_max | :min_less_than_zero}
  @type unlock_request :: AccountStore.UnlockRequest.t()
  @type unlock_result :: :ok | {:error, :insufficient_balance | term}
  @type modify_result :: {:ok, account} | {:error, :not_found | :value_must_be_positive}

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  @spec lock(lock_request) :: lock_result
  def lock(%AccountStore.LockRequest{} = lock_request) do
    GenServer.call(__MODULE__, {:lock, lock_request})
  end

  @spec unlock(unlock_request) :: unlock_result
  def unlock(%AccountStore.UnlockRequest{} = unlock_request) do
    GenServer.call(__MODULE__, {:unlock, unlock_request})
  end

  @spec upsert(account) :: :ok
  def upsert(account) do
    GenServer.call(__MODULE__, {:upsert, account})
  end

  @spec add(venue_id, credential_id, asset, val :: number | String.t() | Decimal.t()) ::
          modify_result
  def add(venue_id, credential_id, asset, val)

  def add(venue_id, credential_id, asset, %Decimal{} = val) do
    GenServer.call(__MODULE__, {:add, venue_id, credential_id, asset, val})
  end

  def add(venue_id, credential_id, asset, val) when is_number(val) or is_binary(val) do
    add(venue_id, credential_id, asset, Decimal.cast(val))
  end

  @spec sub(venue_id, credential_id, asset, val :: number | String.t() | Decimal.t()) ::
          modify_result
  def sub(venue_id, credential_id, asset, val)

  def sub(venue_id, credential_id, asset, %Decimal{} = val) do
    __MODULE__
    |> GenServer.call({:sub, venue_id, credential_id, asset, val})
  end

  def sub(venue_id, credential_id, asset, val) when is_number(val) or is_binary(val) do
    sub(venue_id, credential_id, asset, Decimal.cast(val))
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

  def handle_call({:lock, lock_request}, _from, state) do
    with {:ok, {with_locked_balance, locked_qty}} <-
           AccountStore.Lock.from_request(lock_request) do
      upsert_ets_table(with_locked_balance)

      Tai.Events.info(%Tai.Events.LockAccountOk{
        venue_id: lock_request.venue_id,
        credential_id: lock_request.credential_id,
        asset: lock_request.asset,
        qty: locked_qty,
        min: lock_request.min,
        max: lock_request.max
      })

      {:reply, {:ok, locked_qty}, state}
    else
      {:error, {:insufficient_balance, free}} = error ->
        Tai.Events.info(%Tai.Events.LockAccountInsufficientFunds{
          venue_id: lock_request.venue_id,
          credential_id: lock_request.credential_id,
          asset: lock_request.asset,
          min: lock_request.min,
          max: lock_request.max,
          free: free
        })

        {:reply, error, state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:unlock, unlock_request}, _from, state) do
    with {:ok, with_unlocked_balance} <- AccountStore.Unlock.from_request(unlock_request) do
      upsert_ets_table(with_unlocked_balance)

      Tai.Events.info(%Tai.Events.UnlockAccountOk{
        venue_id: unlock_request.venue_id,
        credential_id: unlock_request.credential_id,
        asset: unlock_request.asset,
        qty: unlock_request.qty
      })

      {:reply, :ok, state}
    else
      {:error, {:insufficient_balance, locked}} = error ->
        Tai.Events.info(%Tai.Events.UnlockAccountInsufficientFunds{
          venue_id: unlock_request.venue_id,
          credential_id: unlock_request.credential_id,
          asset: unlock_request.asset,
          qty: unlock_request.qty,
          locked: locked
        })

        {:reply, error, state}

      {:error, :not_found} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:add, venue_id, credential_id, asset, val}, _from, state) do
    if Decimal.cmp(val, Decimal.new(0)) == :gt do
      case find_by(venue_id: venue_id, credential_id: credential_id, asset: asset) do
        {:ok, account} ->
          new_free = Decimal.add(account.free, val)
          new_account = Map.put(account, :free, new_free)
          upsert_ets_table(new_account)
          continue = {:add, venue_id, credential_id, asset, val, new_account}

          {:reply, {:ok, new_account}, state, {:continue, continue}}

        {:error, _} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_call({:sub, venue_id, credential_id, asset, val}, _from, state) do
    if Decimal.cmp(val, Decimal.new(0)) == :gt do
      case find_by(venue_id: venue_id, credential_id: credential_id, asset: asset) do
        {:ok, account} ->
          new_free = Decimal.sub(account.free, val)

          if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
            {:reply, {:error, :result_less_then_zero}, state}
          else
            new_account = Map.put(account, :free, new_free)
            upsert_ets_table(new_account)
            continue = {:sub, venue_id, credential_id, asset, val, new_account}

            {:reply, {:ok, new_account}, state, {:continue, continue}}
          end

        {:error, _} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_continue({:add, venue_id, credential_id, asset, val, account}, state) do
    Tai.Events.info(%Tai.Events.AddFreeAccount{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: asset,
      val: val,
      free: account.free,
      locked: account.locked
    })

    {:noreply, state}
  end

  def handle_continue({:sub, venue_id, credential_id, asset, val, account}, state) do
    Tai.Events.info(%Tai.Events.SubFreeAccount{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: asset,
      val: val,
      free: account.free,
      locked: account.locked
    })

    {:noreply, state}
  end

  defp upsert_ets_table(account) do
    record = {{account.venue_id, account.credential_id, account.asset, account.type}, account}
    :ets.insert(__MODULE__, record)
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
