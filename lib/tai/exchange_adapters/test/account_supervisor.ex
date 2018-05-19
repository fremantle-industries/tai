defmodule Tai.ExchangeAdapters.Test.AccountSupervisor do
  use Supervisor

  def start_link(account_id) do
    Supervisor.start_link(__MODULE__, account_id, name: :"#{__MODULE__}_#{account_id}")
  end

  def init(account_id) do
    children = [
      {Tai.ExchangeAdapters.Test.Account, account_id}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
