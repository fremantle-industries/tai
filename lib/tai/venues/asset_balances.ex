defmodule Tai.Venues.AssetBalances do
  alias Tai.Venues.AssetBalances
  use GenServer

  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type lock_request :: AssetBalances.LockRequest.t()
  @type lock_result ::
          {:ok, Decimal.t()}
          | {:error,
             :not_found | :insufficient_balance | :min_greater_than_max | :min_less_than_zero}
  @type unlock_request :: AssetBalances.UnlockRequest.t()
  @type unlock_result :: :ok | {:error, :insufficient_balance | term}
  @type modify_result :: {:ok, asset_balance} | {:error, :not_found | :value_must_be_positive}

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  def init(state) do
    Tai.MetaLogger.init_tid()
    {:ok, state}
  end

  def handle_call(:create_ets_table, _from, state) do
    create_ets_table()
    {:reply, :ok, state}
  end

  def handle_call({:upsert, balance}, _from, state) do
    upsert_ets_table(balance)

    Tai.Events.broadcast(%Tai.Events.UpsertAssetBalance{
      venue_id: balance.exchange_id,
      account_id: balance.account_id,
      asset: balance.asset,
      free: balance.free,
      locked: balance.locked
    })

    {:reply, :ok, state}
  end

  def handle_call({:lock, lock_request}, _from, state) do
    with {:ok, {with_locked_balance, locked_qty}} <- AssetBalances.Lock.from_request(lock_request) do
      upsert_ets_table(with_locked_balance)

      Tai.Events.broadcast(%Tai.Events.LockAssetBalanceOk{
        venue_id: lock_request.exchange_id,
        account_id: lock_request.account_id,
        asset: lock_request.asset,
        qty: locked_qty,
        min: lock_request.min,
        max: lock_request.max
      })

      {:reply, {:ok, locked_qty}, state}
    else
      {:error, {:insufficient_balance, free}} = error ->
        Tai.Events.broadcast(%Tai.Events.LockAssetBalanceInsufficientFunds{
          venue_id: lock_request.exchange_id,
          account_id: lock_request.account_id,
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
    with {:ok, with_unlocked_balance} <- AssetBalances.Unlock.from_request(unlock_request) do
      upsert_ets_table(with_unlocked_balance)

      Tai.Events.broadcast(%Tai.Events.UnlockAssetBalanceOk{
        venue_id: unlock_request.exchange_id,
        account_id: unlock_request.account_id,
        asset: unlock_request.asset,
        qty: unlock_request.qty
      })

      {:reply, :ok, state}
    else
      {:error, {:insufficient_balance, locked}} = error ->
        Tai.Events.broadcast(%Tai.Events.UnlockAssetBalanceInsufficientFunds{
          venue_id: unlock_request.exchange_id,
          account_id: unlock_request.account_id,
          asset: unlock_request.asset,
          qty: unlock_request.qty,
          locked: locked
        })

        {:reply, error, state}

      {:error, :not_found} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:add, exchange_id, account_id, asset, val}, _from, state) do
    if Decimal.cmp(val, Decimal.new(0)) == :gt do
      case find_by(exchange_id: exchange_id, account_id: account_id, asset: asset) do
        {:ok, balance} ->
          new_free = Decimal.add(balance.free, val)
          new_balance = Map.put(balance, :free, new_free)
          upsert_ets_table(new_balance)
          continue = {:add, exchange_id, account_id, asset, val, new_balance}

          {:reply, {:ok, new_balance}, state, {:continue, continue}}

        {:error, _} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_call({:sub, exchange_id, account_id, asset, val}, _from, state) do
    if Decimal.cmp(val, Decimal.new(0)) == :gt do
      case find_by(exchange_id: exchange_id, account_id: account_id, asset: asset) do
        {:ok, balance} ->
          new_free = Decimal.sub(balance.free, val)

          if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
            {:reply, {:error, :result_less_then_zero}, state}
          else
            new_balance = Map.put(balance, :free, new_free)
            upsert_ets_table(new_balance)
            continue = {:sub, exchange_id, account_id, asset, val, new_balance}

            {:reply, {:ok, new_balance}, state, {:continue, continue}}
          end

        {:error, _} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_continue({:add, venue_id, account_id, asset, val, balance}, state) do
    Tai.Events.broadcast(%Tai.Events.AddFreeAssetBalance{
      venue_id: venue_id,
      account_id: account_id,
      asset: asset,
      val: val,
      free: balance.free,
      locked: balance.locked
    })

    {:noreply, state}
  end

  def handle_continue({:sub, venue_id, account_id, asset, val, balance}, state) do
    Tai.Events.broadcast(%Tai.Events.SubFreeAssetBalance{
      venue_id: venue_id,
      account_id: account_id,
      asset: asset,
      val: val,
      free: balance.free,
      locked: balance.locked
    })

    {:noreply, state}
  end

  @spec lock(lock_request) :: lock_result
  def lock(%AssetBalances.LockRequest{} = lock_request) do
    GenServer.call(__MODULE__, {:lock, lock_request})
  end

  @spec unlock(unlock_request) :: unlock_result
  def unlock(%AssetBalances.UnlockRequest{} = unlock_request) do
    GenServer.call(__MODULE__, {:unlock, unlock_request})
  end

  @spec upsert(balance :: asset_balance) :: :ok
  def upsert(balance) do
    GenServer.call(__MODULE__, {:upsert, balance})
  end

  @spec add(
          exchange_id :: atom,
          account_id :: atom,
          asset :: atom,
          val :: number | String.t() | Decimal.t()
        ) :: modify_result
  def add(exchange_id, account_id, asset, val)

  def add(exchange_id, account_id, asset, %Decimal{} = val) do
    GenServer.call(
      __MODULE__,
      {:add, exchange_id, account_id, asset, val}
    )
  end

  def add(exchange_id, account_id, asset, val) when is_number(val) or is_binary(val) do
    add(exchange_id, account_id, asset, to_decimal(val))
  end

  @spec sub(
          exchange_id :: atom,
          account_id :: atom,
          asset :: atom,
          val :: number | String.t() | Decimal.t()
        ) :: modify_result
  def sub(exchange_id, account_id, asset, val)

  def sub(exchange_id, account_id, asset, %Decimal{} = val) do
    __MODULE__
    |> GenServer.call({:sub, exchange_id, account_id, asset, val})
  end

  def sub(exchange_id, account_id, asset, val) when is_number(val) or is_binary(val) do
    sub(exchange_id, account_id, asset, to_decimal(val))
  end

  @spec all :: [asset_balance]
  def all() do
    __MODULE__
    |> :ets.select([{{:_, :_}, [], [:"$_"]}])
    |> Enum.reduce(
      [],
      fn {_, balance}, acc -> [balance | acc] end
    )
  end

  @spec where(filters :: [...]) :: [asset_balance]
  def where(filters) do
    all()
    |> Enum.reduce(
      [],
      fn balance, acc ->
        matched_all_filters =
          filters
          |> Keyword.keys()
          |> Enum.all?(fn filter ->
            case filter do
              :exchange_id ->
                balance.exchange_id == Keyword.get(filters, filter)

              :account_id ->
                balance.account_id == Keyword.get(filters, filter)

              :asset ->
                balance.asset == Keyword.get(filters, filter)

              _ ->
                Map.get(balance, filter) == Keyword.get(filters, filter)
            end
          end)

        if matched_all_filters do
          [balance | acc]
        else
          acc
        end
      end
    )
  end

  @spec find_by(filters :: [...]) :: {:ok, asset_balance} | {:error, :not_found}
  def find_by(filters) do
    with %Tai.Venues.AssetBalance{} = balance <- filters |> where() |> List.first() do
      {:ok, balance}
    else
      nil ->
        {:error, :not_found}
    end
  end

  defp upsert_ets_table(balance) do
    record = {{balance.exchange_id, balance.account_id, balance.asset}, balance}
    :ets.insert(__MODULE__, record)
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end

  defp to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  defp to_decimal(val), do: val |> Decimal.new()
end
