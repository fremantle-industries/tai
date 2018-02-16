defmodule Tai.Fund do
  alias Tai.Markets.Currency

  def balance do
    Tai.Exchanges.Config.exchange_ids
    |> Enum.map(&Tai.Exchange.balance/1)
    |> Currency.sum
  end
end
