defmodule Tai.Exchanges.Balance do
  @moduledoc """
  Manages the balances of an account
  """

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

  def all(account_id) do
    account_id
    |> to_name
    |> GenServer.call(:all)
  end

  @doc """
  Returns an atom which identifies the process for the given account id

  ## Examples

    iex> Tai.Exchanges.Balance.to_name(:my_test_account)
    :"Elixir.Tai.Exchanges.Balance_my_test_account"
  """
  def to_name(account_id) do
    :"#{__MODULE__}_#{account_id}"
  end
end
