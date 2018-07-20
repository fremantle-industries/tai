defmodule Tai.ExchangeAdapters.Poloniex.Supervisor do
  @moduledoc """
  Supervisor for the Poloniex exchange adapter
  """

  use Supervisor

  def start_link(%Tai.Exchanges.Config{} = config) do
    Supervisor.start_link(
      __MODULE__,
      config.id,
      name: :"#{__MODULE__}_#{config.id}"
    )
  end

  def init(exchange_id) do
    [
      {Tai.ExchangeAdapters.Poloniex.Products, [exchange_id: exchange_id, whitelist_query: "*"]}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
