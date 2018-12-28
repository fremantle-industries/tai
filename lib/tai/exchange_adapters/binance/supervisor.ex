defmodule Tai.ExchangeAdapters.Binance.Supervisor do
  @moduledoc """
  Supervisor for the Binance exchange adapter
  """

  use Tai.Exchanges.AdapterSupervisor

  def account do
    Tai.ExchangeAdapters.Binance.Account
  end
end
