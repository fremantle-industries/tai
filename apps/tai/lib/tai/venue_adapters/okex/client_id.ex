defmodule Tai.VenueAdapters.OkEx.ClientId do
  @type client_id :: Tai.Trading.Order.client_id()

  @spec to_venue(client_id) :: String.t()
  def to_venue(client_id) do
    {:ok, bin} = client_id |> Ecto.UUID.dump()
    bin |> Base.encode32(padding: false)
  end

  @spec from_base32(String.t()) :: client_id | no_return
  def from_base32(base32) do
    {:ok, client_id} = base32 |> Base.decode32!(padding: false) |> Ecto.UUID.cast()
    client_id
  end
end
