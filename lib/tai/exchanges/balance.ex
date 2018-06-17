defmodule Tai.Exchanges.Balance do
  @moduledoc """
  Manages the balances of an account
  """

  @type lock_request :: Tai.Exchanges.LockRequest.t()

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

  def handle_call({:lock_all, lock_requests}, _from, state) do
    result =
      lock_requests
      |> Enum.reduce(
        %{state: state, errors: []},
        fn lock_request, acc ->
          if detail = Map.get(acc.state, lock_request.asset) do
            new_free = Decimal.sub(detail.free, lock_request.amount)
            new_locked = Decimal.add(detail.locked, lock_request.amount)

            new_detail =
              detail
              |> Map.put(:free, new_free)
              |> Map.put(:locked, new_locked)

            new_state = Map.put(acc.state, lock_request.asset, new_detail)

            new_errors =
              if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
                [lock_request | acc.errors]
              else
                acc.errors
              end

            acc
            |> Map.put(:state, new_state)
            |> Map.put(:errors, new_errors)
          else
            new_errors = [lock_request | acc.errors]

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

  @spec all(atom) :: map
  def all(account_id) do
    account_id
    |> to_name
    |> GenServer.call(:all)
  end

  @spec lock_all(atom, [lock_request, ...]) :: :ok | {:error, [lock_request, ...]}
  def lock_all(account_id, lock_requests) do
    account_id
    |> to_name
    |> GenServer.call({:lock_all, lock_requests})
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
