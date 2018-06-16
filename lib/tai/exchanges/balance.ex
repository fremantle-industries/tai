defmodule Tai.Exchanges.Balance do
  @moduledoc """
  Manages the balances of an account
  """

  @type hold_request :: Tai.Exchanges.HoldRequest.t()

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

  def handle_call({:lock_all, hold_requests}, _from, state) do
    result =
      hold_requests
      |> Enum.reduce(
        %{state: state, errors: []},
        fn hold_request, acc ->
          if detail = Map.get(acc.state, hold_request.asset) do
            new_free = Decimal.sub(detail.free, hold_request.amount)
            new_locked = Decimal.add(detail.locked, hold_request.amount)

            new_detail =
              detail
              |> Map.put(:free, new_free)
              |> Map.put(:locked, new_locked)

            new_state = Map.put(acc.state, hold_request.asset, new_detail)

            new_errors =
              if Decimal.cmp(new_free, Decimal.new(0)) == :lt do
                [hold_request | acc.errors]
              else
                acc.errors
              end

            acc
            |> Map.put(:state, new_state)
            |> Map.put(:errors, new_errors)
          else
            new_errors = [hold_request | acc.errors]

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

  @spec lock_all(atom, [hold_request, ...]) :: :ok | {:error, [hold_request, ...]}
  def lock_all(account_id, hold_requests) do
    account_id
    |> to_name
    |> GenServer.call({:lock_all, hold_requests})
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
