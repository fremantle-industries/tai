defmodule Tai.Exchanges.AssetBalances do
  @moduledoc """
  Manages the balances of an account
  """

  @type balance :: Tai.Exchanges.AssetBalance.t()
  @type balance_range :: Tai.Exchanges.AssetBalanceRange.t()
  @type balance_change_request :: Tai.Exchanges.AssetBalanceChangeRequest.t()

  use GenServer

  require Logger

  def start_link(exchange_id: exchange_id, account_id: account_id, balances: %{} = balances) do
    GenServer.start_link(
      __MODULE__,
      balances,
      name: to_name(exchange_id, account_id)
    )
  end

  def init(balances) do
    Tai.MetaLogger.init_tid()
    {:ok, balances, {:continue, :init}}
  end

  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  def handle_call(
        {:lock_range, %Tai.Exchanges.AssetBalanceRange{} = balance_range},
        _from,
        state
      ) do
    with %Tai.Exchanges.AssetBalance{} = balance <- Map.get(state, balance_range.asset),
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

        new_balance =
          balance
          |> Map.put(:free, new_free)
          |> Map.put(:locked, new_locked)

        new_state = Map.put(state, balance_range.asset, new_balance)

        continue = {
          :lock_range_ok,
          balance_range.asset,
          lock_result,
          balance_range.min,
          balance_range.max
        }

        {:reply, {:ok, lock_result}, new_state, {:continue, continue}}
      end
    else
      {:error, _} = error ->
        {:reply, error, state}

      nil ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(
        {:unlock, %Tai.Exchanges.AssetBalanceChangeRequest{asset: asset, amount: amount}},
        _from,
        state
      ) do
    if detail = Map.get(state, asset) do
      new_free = Decimal.add(detail.free, amount)
      new_locked = Decimal.sub(detail.locked, amount)

      new_detail =
        detail
        |> Map.put(:free, new_free)
        |> Map.put(:locked, new_locked)

      if Decimal.cmp(new_locked, Decimal.new(0)) == :lt do
        continue = {:unlock_insufficient_balance, asset, detail.locked, amount}
        {:reply, {:error, :insufficient_balance}, state, {:continue, continue}}
      else
        new_state = Map.put(state, asset, new_detail)
        continue = {:unlock_ok, asset, amount}
        {:reply, :ok, new_state, {:continue, continue}}
      end
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:add, asset, val}, _from, state) do
    if Decimal.cmp(val, Decimal.new(0)) == :gt do
      case Map.fetch(state, asset) do
        {:ok, balance} ->
          new_free = Decimal.add(balance.free, val)
          new_balance = Map.put(balance, :free, new_free)
          new_state = Map.put(state, asset, new_balance)
          continue = {:add, asset, val, new_balance}

          {:reply, {:ok, new_balance}, new_state, {:continue, continue}}

        :error ->
          {:reply, {:error, :not_found}, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_call({:sub, asset, val}, _from, state) do
    if Decimal.cmp(val, Decimal.new(0)) == :gt do
      case Map.fetch(state, asset) do
        {:ok, balance} ->
          new_free = Decimal.sub(balance.free, val)

          if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
            {:reply, {:error, :result_less_then_zero}, state}
          else
            new_balance = Map.put(balance, :free, new_free)
            new_state = Map.put(state, asset, new_balance)
            continue = {:sub, asset, val, new_balance}

            {:reply, {:ok, new_balance}, new_state, {:continue, continue}}
          end

        :error ->
          {:reply, {:error, :not_found}, state}
      end
    else
      {:reply, {:error, :value_must_be_positive}, state}
    end
  end

  def handle_continue(:init, state) do
    state
    |> Enum.each(fn {asset, balance} ->
      Logger.info("[init,#{asset},#{balance.free},#{balance.locked}]")
    end)

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

  @spec all(exchange_id :: atom, account_id :: atom) :: map
  def all(exchange_id, account_id) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call(:all)
  end

  @spec lock_range(atom, atom, balance_range) ::
          {:ok, Decimal.t()}
          | {:error, :not_found | :insufficient_balance | :min_greater_than_max,
             :min_less_than_zero}
  def lock_range(exchange_id, account_id, range) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:lock_range, range})
  end

  @spec unlock(atom, atom, balance_change_request) ::
          :ok | {:error, :not_found | :insufficient_balance}
  def unlock(exchange_id, account_id, balance_change_request) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:unlock, balance_change_request})
  end

  @spec add(atom, atom, atom, Decimal.t() | number | binary) ::
          {:ok, balance} | {:error, :not_found | :value_must_be_positive}
  def add(exchange_id, account_id, asset, val)

  def add(exchange_id, account_id, asset, %Decimal{} = val) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:add, asset, val})
  end

  def add(exchange_id, account_id, asset, val) when is_number(val) or is_binary(val) do
    add(exchange_id, account_id, asset, Decimal.new(val))
  end

  @spec sub(atom, atom, atom, Decimal.t() | number | binary) ::
          {:ok, balance} | {:error, :not_found | :value_must_be_positive | :result_less_then_zero}
  def sub(exchange_id, account_id, asset, val)

  def sub(exchange_id, account_id, asset, %Decimal{} = val) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:sub, asset, val})
  end

  def sub(exchange_id, account_id, asset, val) when is_number(val) or is_binary(val) do
    sub(exchange_id, account_id, asset, Decimal.new(val))
  end

  @doc """
  Returns an atom which identifies the process for the given account id

  ## Examples

    iex> Tai.Exchanges.AssetBalances.to_name(:my_test_exchange, :my_test_account)
    :"Elixir.Tai.Exchanges.AssetBalances_my_test_exchange_my_test_account"
  """
  @spec to_name(atom, atom) :: atom
  def to_name(exchange_id, account_id) do
    :"#{__MODULE__}_#{exchange_id}_#{account_id}"
  end
end
