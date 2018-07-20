defmodule Tai.ExchangeAdapters.Poloniex.Products do
  @moduledoc """
  Retrieves the available products on the Poloniex exchange

  Minimum Trade Sizes:
  https://thecryptobot.com/2017/11/27/markets-minimum-trade-sizes-poloniex-bittrex-kraken/

  Bitcoin (BTC pairs): 0.0001 BTC
  Ethereum (ETH pairs): 0.0001 ETH
  Monero (XMR pairs): 0.0001 XMR
  Tether (USDT pairs): 0.0001 USDT
  """

  use GenServer

  def start_link([exchange_id: _, whitelist_query: _] = state) do
    GenServer.start_link(
      __MODULE__,
      state,
      name: state |> to_name
    )
  end

  def init(exchange_id) do
    {:ok, exchange_id, 0}
  end

  def handle_info(:timeout, exchange_id) do
    fetch!(exchange_id)
    {:noreply, exchange_id}
  end

  defp to_name(exchange_id: exchange_id, whitelist_query: _) do
    :"#{__MODULE__}_#{exchange_id}"
  end

  defp fetch!(exchange_id: exchange_id, whitelist_query: query) do
    with {:ok, %{} = exchange_tickers} <- ExPoloniex.Public.return_ticker() do
      exchange_tickers
      |> index_by_symbol(exchange_id)
      |> Juice.squeeze(query)
      |> Enum.each(&upsert_product/1)

      Tai.Boot.fetched_products(exchange_id)
    end
  end

  defp index_by_symbol(exchange_tickers, exchange_id) do
    exchange_tickers
    |> Enum.reduce(
      %{},
      fn {exchange_symbol, info}, acc ->
        [quote_asset, base_asset] = String.split(exchange_symbol, "_")
        symbol = Tai.Symbol.build(base_asset, quote_asset)

        Map.put(acc, symbol, {exchange_id, exchange_symbol, info})
      end
    )
  end

  @min_notional Decimal.new(0.0001)
  defp upsert_product({
         symbol,
         {
           exchange_id,
           exchange_symbol,
           %{"isFrozen" => is_frozen}
         }
       }) do
    with status <- tai_status(is_frozen) do
      %Tai.Exchanges.Product{
        exchange_id: exchange_id,
        symbol: symbol,
        exchange_symbol: exchange_symbol,
        status: status,
        min_notional: @min_notional
      }
      |> Tai.Exchanges.Products.upsert()
    end
  end

  defp tai_status("0"), do: Tai.Exchanges.ProductStatus.trading()
  defp tai_status("1"), do: Tai.Exchanges.ProductStatus.halt()
end
