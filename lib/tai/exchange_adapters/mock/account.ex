defmodule Tai.ExchangeAdapters.Mock.Account do
  use Tai.Exchanges.Account

  require Logger

  def all_balances(_credentials) do
    {:ok, %{}}
  end

  def buy_limit(symbol, price, size, time_in_force, _credentials) do
    eject_buy_or_sell_limit(symbol, price, size, time_in_force)
  end

  def sell_limit(symbol, price, size, time_in_force, _credentials) do
    eject_buy_or_sell_limit(symbol, price, size, time_in_force)
  end

  def cancel_order(server_id, _credentials) do
    with_mock_server(fn ->
      server_id
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, :cancel_ok} -> {:ok, server_id}
        {:error, :not_found} -> {:error, :mock_not_found}
      end
    end)
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

  defp with_mock_server(func) do
    try do
      func.()
    catch
      :exit, {:noproc, {GenServer, :call, [Tai.TestSupport.Mocks.Server, _, _]}} ->
        {:error, :mock_server_not_started}
    end
  end
end
