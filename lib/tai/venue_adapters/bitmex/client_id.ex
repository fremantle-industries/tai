defmodule Tai.VenueAdapters.Bitmex.ClientId do
  @type client_id :: Tai.Trading.Order.client_id()
  @type time_in_force :: Tai.Trading.Order.time_in_force()

  @spec to_venue(client_id, time_in_force) :: String.t()
  def to_venue(client_id, time_in_force) do
    {:ok, bin} = client_id |> Ecto.UUID.dump()
    base64 = bin |> Base.encode64()
    "#{time_in_force}-#{base64}"
  end

  @spec from_base64(String.t()) :: client_id | no_return
  def from_base64(base64) do
    {:ok, client_id} = base64 |> Base.decode64!() |> Ecto.UUID.cast()
    client_id
  end
end
