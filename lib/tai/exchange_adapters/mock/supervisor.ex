defmodule Tai.ExchangeAdapters.Mock.Supervisor do
  @moduledoc """
  Supervisor for the mock exchange adapter
  """

  use Tai.Venues.AdapterSupervisor

  def account() do
    Tai.ExchangeAdapters.Mock.Account
  end
end
