defmodule Tai.Fund do
  def balance do
    Tai.Settings.exchange_ids
    |> Enum.map(&Tai.Exchange.balance/1)
    |> Tai.Currency.sum
  end
end
