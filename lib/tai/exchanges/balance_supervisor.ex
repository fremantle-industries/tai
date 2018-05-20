defmodule Tai.Exchanges.BalanceSupervisor do
  @moduledoc """
  Supervisor that starts a balance process for every symbol in an account
  """

  use Supervisor

  alias Tai.Exchanges

  def start_link(account_id) do
    Supervisor.start_link(
      __MODULE__,
      account_id,
      name: :"#{__MODULE__}_#{account_id}"
    )
  end

  def init(account_id) do
    with {:ok, balances} <- Exchanges.Account.all_balances(account_id) do
      [
        {Exchanges.Balance, [account_id: account_id, balances: balances]}
      ]
      |> Supervisor.init(strategy: :one_for_one)
    end
  end
end
