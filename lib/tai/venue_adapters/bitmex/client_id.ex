defmodule Tai.VenueAdapters.Bitmex.ClientId do
  @type client_id :: Tai.Trading.Order.client_id()
  @type time_in_force :: Tai.Trading.Order.time_in_force()

  @spec to_venue(client_id, time_in_force) :: String.t()
  def to_venue(client_id, time_in_force) do
    {:ok, bin} = client_id |> Ecto.UUID.dump()
    base64 = bin |> Base.encode64()
    "#{time_in_force}-#{base64}"
  end
end
