defmodule Tai.ExchangeAdapters.Poloniex.Supervisor do
  @moduledoc """
  Supervisor for the Poloniex exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def products() do
    Tai.ExchangeAdapters.Poloniex.Products
  end
end
