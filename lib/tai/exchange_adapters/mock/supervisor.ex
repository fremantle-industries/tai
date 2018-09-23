defmodule Tai.ExchangeAdapters.Mock.Supervisor do
  @moduledoc """
  Supervisor for the mock exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def hydrate_fees() do
    Tai.ExchangeAdapters.Mock.HydrateFees
  end

  def hydrate_products() do
    Tai.ExchangeAdapters.Mock.HydrateProducts
  end

  def account() do
    Tai.ExchangeAdapters.Mock.Account
  end
end
