defmodule Tai.ExchangeAdapters.Test.Supervisor do
  @moduledoc """
  Supervisor for the test exchange adapter
  """

  use Supervisor

  def start_link(%Tai.Exchanges.Config{} = config) do
    Supervisor.start_link(
      __MODULE__,
      config.id,
      name: :"#{__MODULE__}_#{config.id}"
    )
  end

  def init(_config) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
