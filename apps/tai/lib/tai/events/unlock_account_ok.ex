defmodule Tai.Events.UnlockAccountOk do
  alias __MODULE__

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type credential_id :: Tai.Venues.Adapter.credential_id()
  @type t :: %UnlockAccountOk{
          venue_id: venue_id,
          credential_id: credential_id,
          asset: atom,
          qty: Decimal.t()
        }

  @enforce_keys ~w(
    venue_id
    credential_id
    asset
    qty
  )a
  defstruct ~w(
    venue_id
    credential_id
    asset
    qty
  )a
end

defimpl Tai.LogEvent, for: Tai.Events.UnlockAccountOk do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:qty, event.qty |> Decimal.to_string(:normal))
  end
end
