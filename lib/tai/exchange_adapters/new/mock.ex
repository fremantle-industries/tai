defmodule Tai.ExchangeAdapters.New.Mock do
  use Tai.Exchanges.Adapter

  import Tai.TestSupport.Mocks.Client

  def products(exchange_id) do
    with_mock_server(fn ->
      exchange_id
      |> products_response_key()
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, products} -> {:ok, products}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def asset_balances(exchange_id, account_id, _credentials) do
    with_mock_server(fn ->
      {exchange_id, account_id}
      |> asset_balances_response_key()
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, asset_balances} -> {:ok, asset_balances}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def maker_taker_fees(exchange_id, account_id, _credentials) do
    with_mock_server(fn ->
      {exchange_id, account_id}
      |> maker_taker_fees_response_key()
      |> Tai.TestSupport.Mocks.Server.eject()
      |> case do
        {:ok, fees} -> {:ok, fees}
        {:error, :not_found} -> {:error, :mock_response_not_found}
      end
    end)
  end

  def products_response_key(exchange_id), do: {__MODULE__, :products, exchange_id}

  def asset_balances_response_key({exchange_id, account_id}),
    do: {__MODULE__, :asset_balances, exchange_id, account_id}

  def maker_taker_fees_response_key({exchange_id, account_id}),
    do: {__MODULE__, :maker_taker_fees, exchange_id, account_id}
end
