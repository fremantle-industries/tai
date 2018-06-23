defmodule Tai.Exchanges.Balance do
  @moduledoc """
  Manages the balances of an account
  """

  @type balance_change_request :: Tai.Exchanges.BalanceChangeRequest.t()

  use GenServer

  def start_link(account_id: account_id, balances: %{} = balances) do
    GenServer.start_link(
      __MODULE__,
      balances,
      name: account_id |> to_name
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

  @spec all(atom) :: map
  def all(account_id) do
    account_id
    |> to_name
    |> GenServer.call(:all)
  end

  @spec lock(atom, balance_change_request) :: :ok | {:error, :not_found | :insufficient_balance}
  def lock(account_id, balance_change_request) do
    account_id
    |> to_name
    |> GenServer.call({:lock, balance_change_request})
  end

  @spec unlock(atom, balance_change_request) :: :ok | {:error, :not_found | :insufficient_balance}
  def unlock(account_id, balance_change_request) do
    account_id
    |> to_name
    |> GenServer.call({:unlock, balance_change_request})
  end

  @doc """
  Returns an atom which identifies the process for the given account id

  ## Examples

    iex> Tai.Exchanges.Balance.to_name(:my_test_account)
    :"Elixir.Tai.Exchanges.Balance_my_test_account"
  """
  @spec to_name(atom) :: atom
  def to_name(account_id) do
    :"#{__MODULE__}_#{account_id}"
  end
end
