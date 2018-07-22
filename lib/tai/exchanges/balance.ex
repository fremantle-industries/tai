defmodule Tai.Exchanges.Balance do
  @moduledoc """
  Manages the balances of an account
  """

  @type balance_change_request :: Tai.Exchanges.BalanceChangeRequest.t()

  use GenServer

  def start_link(exchange_id: exchange_id, account_id: account_id, balances: %{} = balances) do
    GenServer.start_link(
      __MODULE__,
      balances,
      name: to_name(exchange_id, account_id)
    )
  end

  def init(balances) do
    {:ok, balances}
  end

  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  def handle_call(
        {:lock, %Tai.Exchanges.BalanceChangeRequest{asset: asset, amount: amount}},
        _from,
        state
      ) do
    if detail = Map.get(state, asset) do
      new_free = Decimal.sub(detail.free, amount)
      new_locked = Decimal.add(detail.locked, amount)

      new_detail =
        detail
        |> Map.put(:free, new_free)
        |> Map.put(:locked, new_locked)

      if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
        {:reply, {:error, :insufficient_balance}, state}
      else
        new_state = Map.put(state, asset, new_detail)
        {:reply, :ok, new_state}
      end
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(
        {:unlock, %Tai.Exchanges.BalanceChangeRequest{asset: asset, amount: amount}},
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
        {:reply, {:error, :insufficient_balance}, state}
      else
        new_state = Map.put(state, asset, new_detail)
        {:reply, :ok, new_state}
      end
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @spec all(atom, atom) :: map
  def all(exchange_id, account_id) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call(:all)
  end

  @spec lock(atom, atom, balance_change_request) ::
          :ok | {:error, :not_found | :insufficient_balance}
  def lock(exchange_id, account_id, balance_change_request) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:lock, balance_change_request})
  end

  @spec unlock(atom, atom, balance_change_request) ::
          :ok | {:error, :not_found | :insufficient_balance}
  def unlock(exchange_id, account_id, balance_change_request) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:unlock, balance_change_request})
  end

  @doc """
  Returns an atom which identifies the process for the given account id

  ## Examples

    iex> Tai.Exchanges.Balance.to_name(:my_test_exchange, :my_test_account)
    :"Elixir.Tai.Exchanges.Balance_my_test_exchange_my_test_account"
  """
  @spec to_name(atom, atom) :: atom
  def to_name(exchange_id, account_id) do
    :"#{__MODULE__}_#{exchange_id}_#{account_id}"
  end
end
