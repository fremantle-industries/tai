defmodule Tai.Supervisor do
  @moduledoc """
  Root supervisor for tai components
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
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

    Supervisor.init(children, strategy: :one_for_one)
  end
end
