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

  def start_link(exchange_id) do
    GenServer.start_link(
      __MODULE__,
      exchange_id,
      name: :"#{__MODULE__}_#{exchange_id}"
    )
  end

  def init(exchange_id) do
    {:ok, exchange_id, 0}
  end

  def handle_info(:timeout, exchange_id) do
    fetch!(exchange_id)
    {:noreply, exchange_id}
  end

  defp fetch!(exchange_id) do
    with {:ok, tickers} <- ExPoloniex.Public.return_ticker() do
      Enum.each(tickers, &upsert_product(&1, exchange_id))
      Tai.Boot.fetched_products(exchange_id)
    end
  end

  @min_notional Decimal.new(0.0001)
  defp upsert_product(
         {exchange_symbol, %{"isFrozen" => is_frozen}},
         exchange_id
       ) do
    with [quote_asset, base_asset] <- String.split(exchange_symbol, "_"),
         symbol <- Tai.Symbol.build(base_asset, quote_asset),
         status <- tai_status(is_frozen) do
      %Tai.Exchanges.Product{
        exchange_id: exchange_id,
        symbol: symbol,
        exchange_symbol: exchange_symbol,
        status: status,
        min_price: nil,
        max_price: nil,
        tick_size: nil,
        min_size: nil,
        max_size: nil,
        step_size: nil,
        min_notional: @min_notional
      }
      |> Tai.Exchanges.Products.upsert()
    end
  end

  defp tai_status("0"), do: Tai.Exchanges.ProductStatus.trading()
  defp tai_status("1"), do: Tai.Exchanges.ProductStatus.halt()
end
