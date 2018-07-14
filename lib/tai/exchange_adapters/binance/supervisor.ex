defmodule Tai.ExchangeAdapters.Binance.Supervisor do
  @moduledoc """
  Supervisor for the binance exchange adapter
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
      {Tai.ExchangeAdapters.Binance.Products, exchange_id}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
