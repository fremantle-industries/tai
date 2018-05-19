defmodule Tai.ExchangeAdapters.Gdax.AccountSupervisor do
  use Supervisor

  def start_link(account_id) do
    Supervisor.start_link(__MODULE__, account_id, name: :"#{__MODULE__}_#{account_id}")
  end

  def init(account_id) do
    [
      {Tai.ExchangeAdapters.Gdax.Account, account_id}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
