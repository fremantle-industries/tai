defmodule Tai.ExchangeAdapters.Test.Supervisor do
  use Supervisor

  def start_link(exchange_id) do
    Supervisor.start_link(__MODULE__, exchange_id, name: :"#{__MODULE__}_#{exchange_id}")
  end

  def init(exchange_id) do
    children = [
      {Tai.ExchangeAdapters.Test.Account, exchange_id}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
