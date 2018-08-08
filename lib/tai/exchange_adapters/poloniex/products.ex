defmodule Tai.ExchangeAdapters.Poloniex.Products do
  @moduledoc """
  Retrieves the available products on the Poloniex exchange

  https://thecryptobot.com/2017/11/27/markets-minimum-trade-sizes-poloniex-bittrex-kraken/

  Min Notional Trade Size:
  Bitcoin (BTC pairs): 0.0001 BTC
  Ethereum (ETH pairs): 0.0001 ETH
  Monero (XMR pairs): 0.0001 XMR
  Tether (USDT pairs): 1.0 USDT

  Min Size:
  Bitcoin (BTC pairs): 0.000001 BTC
  Ethereum (ETH pairs): 0.000001 ETH
  Monero (XMR pairs): 0.000001 XMR
  Tether (USDT pairs): 0.000001 USDT

  Min Price:
  Bitcoin (BTC pairs): 0.00000001 BTC
  Ethereum (ETH pairs): 0.00000001 ETH
  Monero (XMR pairs): 0.00000001 XMR
  Tether (USDT pairs): 0.00000001 USDT

  Max Price:
  Bitcoin (BTC pairs): 100000.0 BTC
  Ethereum (ETH pairs): 100000.0 ETH
  Monero (XMR pairs): 100000.0 XMR
  Tether (USDT pairs): 100000.0 USDT
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

  @min_notional %{
    btc: Decimal.new(0.0001),
    eth: Decimal.new(0.0001),
    xmr: Decimal.new(0.0001),
    usdt: Decimal.new(1.0)
  }
  @min_size Decimal.new(0.000001)
  @min_price Decimal.new(0.00000001)
  @max_price Decimal.new(100_000.0)
  defp upsert_product({
         symbol,
         {
           exchange_id,
           exchange_symbol,
           %{"isFrozen" => is_frozen}
         }
       }) do
    with status <- tai_status(is_frozen),
         {:ok, {_, quote_asset}} <- Tai.Symbol.base_and_quote(symbol),
         min_notional <- Map.get(@min_notional, quote_asset) do
      %Tai.Exchanges.Product{
        exchange_id: exchange_id,
        symbol: symbol,
        exchange_symbol: exchange_symbol,
        status: status,
        min_notional: min_notional,
        min_size: @min_size,
        min_price: @min_price,
        max_price: @max_price
      }
      |> Tai.Exchanges.Products.upsert()
    end
  end

  defp tai_status("0"), do: Tai.Exchanges.ProductStatus.trading()
  defp tai_status("1"), do: Tai.Exchanges.ProductStatus.halt()
end
