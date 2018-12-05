defmodule Tai.ExchangeAdapters.Poloniex.Supervisor do
  @moduledoc """
  Supervisor for the Poloniex exchange adapter
  """

  use Tai.Venues.AdapterSupervisor

  def account do
    Tai.ExchangeAdapters.Poloniex.Account
  end
end
