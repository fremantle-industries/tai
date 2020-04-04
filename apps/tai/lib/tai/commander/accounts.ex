defmodule Tai.Commander.Accounts do
  @type account :: Tai.Venues.Account.t()

  @spec get :: [account]
  def get do
    Tai.Venues.AccountStore.all()
    |> Enum.sort(&(&1.asset >= &2.asset))
    |> Enum.sort(&(&1.venue_id >= &2.venue_id))
  end
end
