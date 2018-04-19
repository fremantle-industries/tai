defmodule Tai.Fund do
  alias Tai.{Exchanges.Account, Exchanges.Config, Markets.Currency}

  def balance do
    Config.exchange_ids()
    |> Enum.map(&Account.balance/1)
    |> Currency.sum()
  end
end
