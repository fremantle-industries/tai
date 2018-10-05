defmodule Tai.ExchangeAdapters.New.Binance do
  use Tai.Exchanges.Adapter

  defdelegate products(exchange_id), to: Tai.ExchangeAdapters.New.Binance.Products

  defdelegate asset_balances(exchange_id, account_id, credentials),
    to: Tai.ExchangeAdapters.New.Binance.AssetBalances

  defdelegate maker_taker_fees(exchange_id, account_id, credentials),
    to: Tai.ExchangeAdapters.New.Binance.MakerTakerFees
end
