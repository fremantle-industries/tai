defmodule Tai.ExchangeAdapters.Gdax.Supervisor do
  @moduledoc """
  Supervisor for the GDAX exchange adapter
  """

  use Tai.Venues.AdapterSupervisor

  def account do
    Tai.ExchangeAdapters.Gdax.Account
  end
end
