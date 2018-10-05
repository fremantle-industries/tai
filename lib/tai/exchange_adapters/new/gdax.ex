defmodule Tai.ExchangeAdapters.New.Gdax do
  use Tai.Exchanges.Adapter

  defdelegate products(exchange_id), to: Tai.ExchangeAdapters.New.Gdax.Products

  defdelegate asset_balances(exchange_id, account_id, credentials),
    to: Tai.ExchangeAdapters.New.Gdax.AssetBalances

  defdelegate maker_taker_fees(exchange_id, account_id, credentials),
    to: Tai.ExchangeAdapters.New.Gdax.MakerTakerFees
end
