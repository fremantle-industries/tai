defmodule Tai do
  use Application

  def start(_type, _args) do
    children = [
      Tai.PubSub,
      {Tai.Settings, Tai.Config.all()},
      Tai.Exchanges.Products,
      Tai.Exchanges.Fees,
      Tai.Exchanges.AssetBalances,
      Tai.Trading.OrderStore,
      Tai.Advisors.Supervisor,
      Tai.Exchanges.AdaptersSupervisor,
      # TODO
      # OrderBookFeedsSupervisor will become the responsibility of each 
      # individual adapter supervisor. Once complete it can be removed.
      Tai.Exchanges.OrderBookFeedsSupervisor
    ]

    opts = [strategy: :one_for_one, name: Tai.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
