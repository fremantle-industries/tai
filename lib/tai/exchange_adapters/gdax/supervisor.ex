defmodule Tai.ExchangeAdapters.Gdax.Supervisor do
  @moduledoc """
  Supervisor for the GDAX exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def products() do
    Tai.ExchangeAdapters.Gdax.Products
  end

  def hydrate_fees() do
    Tai.ExchangeAdapters.Gdax.HydrateFees
  end

  def account() do
    Tai.ExchangeAdapters.Gdax.Account
  end
end
