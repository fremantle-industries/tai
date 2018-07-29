defmodule Tai.Exchanges.AssetBalancesSupervisor do
  use Supervisor

  def start_link([exchange_id: exchange_id, accounts: _] = state) do
    Supervisor.start_link(
      __MODULE__,
      state,
      name: :"#{__MODULE__}_#{exchange_id}"
    )
  end

  def init(exchange_id: exchange_id, accounts: accounts) do
    accounts
    |> Enum.map(fn {account_id, _} ->
      with {:ok, balances} <- Tai.Exchanges.Account.all_balances(exchange_id, account_id) do
        {Tai.Exchanges.AssetBalances,
         [exchange_id: exchange_id, account_id: account_id, balances: balances]}
      end
    end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
