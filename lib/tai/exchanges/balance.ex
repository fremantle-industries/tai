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

  def handle_call({:lock_all, balance_change_requests}, _from, state) do
    result =
      balance_change_requests
      |> Enum.reduce(
        %{state: state, errors: []},
        fn balance_change_request, acc ->
          if detail = Map.get(acc.state, balance_change_request.asset) do
            new_free = Decimal.sub(detail.free, balance_change_request.amount)
            new_locked = Decimal.add(detail.locked, balance_change_request.amount)

            new_detail =
              detail
              |> Map.put(:free, new_free)
              |> Map.put(:locked, new_locked)

            new_state = Map.put(acc.state, balance_change_request.asset, new_detail)

            new_errors =
              if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
                [{:insufficient_balance, balance_change_request} | acc.errors]
              else
                acc.errors
              end

            acc
            |> Map.put(:state, new_state)
            |> Map.put(:errors, new_errors)
          else
            new_errors = [{:not_found, balance_change_request} | acc.errors]

            acc
            |> Map.put(:errors, new_errors)
          end
        end
      )

    if Enum.empty?(result.errors) do
      {:reply, :ok, result.state}
    else
      sorted_errors = Enum.reverse(result.errors)
      {:reply, {:error, sorted_errors}, state}
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

  @spec lock_all(atom, [balance_change_request, ...]) ::
          :ok | {:error, [{:not_found | :insufficient_balance, balance_change_request}, ...]}
  def lock_all(account_id, balance_change_requests) do
    account_id
    |> to_name
    |> GenServer.call({:lock_all, balance_change_requests})
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
