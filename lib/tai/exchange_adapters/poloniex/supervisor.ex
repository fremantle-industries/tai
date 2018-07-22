defmodule Tai.ExchangeAdapters.Poloniex.Supervisor do
  @moduledoc """
  Supervisor for the Poloniex exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def products() do
    Tai.ExchangeAdapters.Poloniex.Products
  end

  def account() do
    Tai.ExchangeAdapters.Poloniex.Account
  end
end
