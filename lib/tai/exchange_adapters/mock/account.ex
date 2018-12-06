defmodule Tai.ExchangeAdapters.Mock.Account do
  use Tai.Exchanges.Account
  import Tai.TestSupport.Mocks.Client

  def all_balances(_credentials) do
    {:ok, %{}}
  end

  def create_order(%Tai.Trading.Order{} = order, _credentials) do
    eject_buy_or_sell_limit(order.symbol, order.price, order.size, order.time_in_force)
  end

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

  defp eject_buy_or_sell_limit(symbol, price, size, time_in_force) do
    with_mock_server(fn ->
      {symbol, price, size, time_in_force}
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, _response} = result -> result
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
  end
end
