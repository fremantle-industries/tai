defmodule Tai.ExchangeAdapters.Test.Supervisor do
  @moduledoc """
  Supervisor for the test exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def products() do
    Tai.ExchangeAdapters.Test.Products
  end
end
