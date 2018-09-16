defmodule Tai.ExchangeAdapters.Test.Supervisor do
  @moduledoc """
  Supervisor for the test exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def hydrate_products do
    Tai.ExchangeAdapters.Test.HydrateProducts
  end

  def hydrate_fees do
    Tai.ExchangeAdapters.Test.HydrateFees
  end

  def account do
    Tai.ExchangeAdapters.Test.Account
  end
end
