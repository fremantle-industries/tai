defmodule Tai.ExchangeAdapters.Poloniex.HydrateFees do
  use Tai.Exchanges.HydrateFees

  def maker_taker(_exchange_id, _account_id) do
    {:ok, %{"makerFee" => maker_fee, "takerFee" => taker_fee}} =
      ExPoloniex.Trading.return_fee_info()

    maker = Decimal.new(maker_fee)
    taker = Decimal.new(taker_fee)

    {:ok, {maker, taker}}
  end
end
