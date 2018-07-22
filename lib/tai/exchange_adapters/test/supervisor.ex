defmodule Tai.ExchangeAdapters.Test.Supervisor do
  @moduledoc """
  Supervisor for the test exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def products() do
    Tai.ExchangeAdapters.Test.Products
  end

  def account() do
    Tai.ExchangeAdapters.Test.Account
  end
end
