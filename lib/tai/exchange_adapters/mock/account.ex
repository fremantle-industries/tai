defmodule Tai.ExchangeAdapters.Mock.Account do
  use Tai.Exchanges.Account
  import Tai.TestSupport.Mocks.Client

  defdelegate create_order(order, credentials), to: Tai.VenueAdapters.Mock

  def cancel_order(venue_order_id, _credentials) do
    with_mock_server(fn ->
      venue_order_id
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, :cancel_ok} -> {:ok, venue_order_id}
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end

  def order_status(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end
end
