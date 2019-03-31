defmodule Tai.VenueAdapters.Poloniex.Products do
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

  def products(venue_id) do
    with {:ok, %{} = exchange_tickers} <- ExPoloniex.Public.return_ticker() do
      products = Enum.map(exchange_tickers, &build(&1, venue_id))
      {:ok, products}
    else
      {:error, %HTTPoison.Error{id: nil, reason: "timeout"}} ->
        {:error, :timeout}
    end
  end

  @min_notional %{
    btc: Decimal.new("0.0001"),
    eth: Decimal.new("0.0001"),
    xmr: Decimal.new("0.0001"),
    usdt: Decimal.new("1.0")
  }
  @min_size Decimal.new("0.000001")
  @min_price Decimal.new("0.00000001")
  @max_price Decimal.new("100000.0")
  defp build({exchange_symbol, %{"isFrozen" => is_frozen}}, venue_id) do
    [exchange_quote_asset, exchange_base_asset] = String.split(exchange_symbol, "_")
    symbol = Tai.Symbol.build(exchange_base_asset, exchange_quote_asset)
    {:ok, status} = Tai.VenueAdapters.Poloniex.ProductStatus.normalize(is_frozen)
    {:ok, {_, quote_asset}} = Tai.Symbol.base_and_quote(symbol)
    min_notional = Map.get(@min_notional, quote_asset)

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol,
      exchange_symbol: exchange_symbol,
      status: status,
      margin: false,
      min_notional: min_notional,
      min_size: @min_size,
      min_price: @min_price,
      max_price: @max_price,
      size_increment: @min_size
    }
  end
end
