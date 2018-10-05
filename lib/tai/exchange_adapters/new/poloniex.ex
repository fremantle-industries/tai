defmodule Tai.ExchangeAdapters.New.Poloniex do
  use Tai.Exchanges.Adapter

  defdelegate products(exchange_id), to: Tai.ExchangeAdapters.New.Poloniex.Products

  defdelegate asset_balances(exchange_id, account_id, credentials),
    to: Tai.ExchangeAdapters.New.Poloniex.AssetBalances

  defdelegate maker_taker_fees(exchange_id, account_id, credentials),
    to: Tai.ExchangeAdapters.New.Poloniex.MakerTakerFees
end
