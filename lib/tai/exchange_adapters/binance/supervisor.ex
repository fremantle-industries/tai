defmodule Tai.ExchangeAdapters.Binance.Supervisor do
  @moduledoc """
  Supervisor for the Binance exchange adapter
  """

  use Supervisor

  def start_link(%Tai.Exchanges.Config{} = config) do
    Supervisor.start_link(
      __MODULE__,
      config,
      name: :"#{__MODULE__}_#{config.id}"
    )
  end

  def init(%Tai.Exchanges.Config{id: exchange_id, products: products}) do
    [
      {Tai.ExchangeAdapters.Binance.Products,
       [exchange_id: exchange_id, whitelist_query: products]}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
