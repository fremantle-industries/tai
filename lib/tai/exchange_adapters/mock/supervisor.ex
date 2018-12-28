defmodule Tai.ExchangeAdapters.Mock.Supervisor do
  @moduledoc """
  Supervisor for the mock exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def account() do
    Tai.ExchangeAdapters.Mock.Account
  end
end
