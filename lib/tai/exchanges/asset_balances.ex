defmodule Tai.Exchanges.AssetBalances do
  @type asset_balance :: Tai.Exchanges.AssetBalance.t()
  @type balance_range :: Tai.Exchanges.AssetBalanceRange.t()

  use GenServer

  require Logger

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

  def handle_call(:clear, _from, state) do
    :ets.delete(__MODULE__)
    create_ets_table()
    {:reply, :ok, state}
  end

  def handle_call({:upsert, balance}, _from, state) do
    upsert_ets_table(balance)

    {
      :reply,
      :ok,
      state,
      {:continue, {:upsert, balance}}
    }
  end

  def handle_call(
        {:lock_range, exchange_id, account_id,
         %Tai.Exchanges.AssetBalanceRange{} = balance_range},
        _from,
        state
      ) do
    with {:ok, balance} <-
           find_by(exchange_id: exchange_id, account_id: account_id, asset: balance_range.asset),
         :ok <- Tai.Exchanges.AssetBalanceRange.validate(balance_range) do
      lock_result =
        cond do
          Decimal.cmp(balance_range.max, balance.free) != :gt -> balance_range.max
          Decimal.cmp(balance_range.min, balance.free) != :gt -> balance.free
          true -> nil
        end

      if lock_result == nil do
        continue = {
          :lock_range_insufficient_balance,
          balance_range.asset,
          balance.free,
          balance_range.min,
          balance_range.max
        }

        {:reply, {:error, :insufficient_balance}, state, {:continue, continue}}
      else
        new_free = Decimal.sub(balance.free, lock_result)
        new_locked = Decimal.add(balance.locked, lock_result)

        balance
        |> Map.put(:free, new_free)
        |> Map.put(:locked, new_locked)
        |> upsert_ets_table()

        continue = {
          :lock_range_ok,
          balance_range.asset,
          lock_result,
          balance_range.min,
          balance_range.max
        }

        {:reply, {:ok, lock_result}, state, {:continue, continue}}
      end
    else
      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call(
        {:unlock, exchange_id, account_id,
         %Tai.Exchanges.AssetBalanceChangeRequest{asset: asset, amount: amount}},
        _from,
        state
      ) do
    with {:ok, balance} <- find_by(exchange_id: exchange_id, account_id: account_id, asset: asset) do
      new_free = Decimal.add(balance.free, amount)
      new_locked = Decimal.sub(balance.locked, amount)

      new_balance =
        balance
        |> Map.put(:free, new_free)
        |> Map.put(:locked, new_locked)

      if Decimal.cmp(new_locked, Decimal.new(0)) == :lt do
        continue = {:unlock_insufficient_balance, asset, balance.locked, amount}
        {:reply, {:error, :insufficient_balance}, state, {:continue, continue}}
      else
        upsert_ets_table(new_balance)
        continue = {:unlock_ok, asset, amount}
        {:reply, :ok, state, {:continue, continue}}
      end
    else
      {:error, _} = error ->
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
          continue = {:add, asset, val, new_balance}

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
            continue = {:sub, asset, val, new_balance}

            {:reply, {:ok, new_balance}, state, {:continue, continue}}
          end

        {:error, _} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_continue({:upsert, balance}, state) do
    Logger.info(
      "[upsert,#{balance.exchange_id},#{balance.account_id},#{balance.asset},#{balance.free},#{
        balance.locked
      }]"
    )

    {:noreply, state}
  end

  def handle_continue({:lock_range_ok, asset, qty, min, max}, state) do
    Logger.info("[lock_range_ok:#{asset},#{qty},#{min}..#{max}]")
    {:noreply, state}
  end

  def handle_continue({:lock_range_insufficient_balance, asset, free, min, max}, state) do
    Logger.warn("[lock_range_insufficient_balance:#{asset},#{free},#{min}..#{max}]")
    {:noreply, state}
  end

  def handle_continue({:unlock_ok, asset, amount}, state) do
    Logger.info("[unlock_ok:#{asset},#{amount}]")
    {:noreply, state}
  end

  def handle_continue({:unlock_insufficient_balance, asset, locked, amount}, state) do
    Logger.warn("[unlock_insufficient_balance:#{asset},#{locked},#{amount}]")
    {:noreply, state}
  end

  def handle_continue({:add, asset, val, balance}, state) do
    Logger.info("[add:#{asset},#{val},#{balance.free},#{balance.locked}]")
    {:noreply, state}
  end

  def handle_continue({:sub, asset, val, balance}, state) do
    Logger.info("[sub:#{asset},#{val},#{balance.free},#{balance.locked}]")
    {:noreply, state}
  end

  @spec clear :: :ok
  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  @spec upsert(balance :: asset_balance) :: :ok
  def upsert(balance) do
    GenServer.call(__MODULE__, {:upsert, balance})
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

  @spec count :: number
  def count do
    all()
    |> Enum.count()
  end

  @spec lock_range(atom, atom, balance_range) ::
          {:ok, Decimal.t()}
          | {:error, :not_found | :insufficient_balance | :min_greater_than_max,
             :min_less_than_zero}
  def lock_range(exchange_id, account_id, range) do
    __MODULE__
    |> GenServer.call({:lock_range, exchange_id, account_id, range})
  end

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
    with %Tai.Exchanges.AssetBalance{} = balance <- filters |> where() |> List.first() do
      {:ok, balance}
    else
      nil ->
        {:error, :not_found}
    end
  end

  def unlock(exchange_id, account_id, balance_change_request) do
    __MODULE__
    |> GenServer.call({:unlock, exchange_id, account_id, balance_change_request})
  end

  def add(exchange_id, account_id, asset, %Decimal{} = val) do
    __MODULE__
    |> GenServer.call({:add, exchange_id, account_id, asset, val})
  end

  def add(exchange_id, account_id, asset, val) when is_number(val) or is_binary(val) do
    add(exchange_id, account_id, asset, Decimal.new(val))
  end

  def sub(exchange_id, account_id, asset, %Decimal{} = val) do
    __MODULE__
    |> GenServer.call({:sub, exchange_id, account_id, asset, val})
  end

  def sub(exchange_id, account_id, asset, val) when is_number(val) or is_binary(val) do
    sub(exchange_id, account_id, asset, Decimal.new(val))
  end

  defp upsert_ets_table(balance) do
    record = {{balance.exchange_id, balance.account_id, balance.asset}, balance}
    :ets.insert(__MODULE__, record)
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end
end
