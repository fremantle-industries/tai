defmodule Tai.Exchanges.AccountsSupervisor do
  use Supervisor

  def start_link([adapter: _, exchange_id: exchange_id, accounts: _] = state) do
    Supervisor.start_link(
      __MODULE__,
      state,
      name: :"#{__MODULE__}_#{exchange_id}"
    )
  end

  def init(adapter: adapter, exchange_id: exchange_id, accounts: accounts) do
    accounts
    |> Enum.map(fn {account_id, _} ->
      {adapter, [exchange_id: exchange_id, account_id: account_id]}
    end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
