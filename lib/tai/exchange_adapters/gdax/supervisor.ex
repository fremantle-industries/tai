defmodule Tai.ExchangeAdapters.Gdax.Supervisor do
  @moduledoc """
  Supervisor for the GDAX exchange adapter
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
      {Tai.ExchangeAdapters.Gdax.Products, [exchange_id: exchange_id, whitelist_query: products]}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
