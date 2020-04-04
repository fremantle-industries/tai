defmodule Tai.Commander.Fees do
  @type fee :: Tai.Venues.FeeInfo.t()

  @spec get :: [fee]
  def get do
    Tai.Venues.FeeStore.all()
    |> Enum.sort(&(&1.venue_id < &2.venue_id))
  end
end
