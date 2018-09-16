defmodule Tai.ExchangeAdapters.Poloniex.Supervisor do
  @moduledoc """
  Supervisor for the Poloniex exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def hydrate_products do
    Tai.ExchangeAdapters.Poloniex.HydrateProducts
  end

  def hydrate_fees do
    Tai.ExchangeAdapters.Poloniex.HydrateFees
  end

  def account do
    Tai.ExchangeAdapters.Poloniex.Account
  end
end
