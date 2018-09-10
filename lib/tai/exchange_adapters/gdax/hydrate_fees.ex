defmodule Tai.ExchangeAdapters.Gdax.HydrateFees do
  use Tai.Exchanges.HydrateFees

  # TODO:
  # When API endpoint is added for user fee rate it should be used to get 
  # an accurate value for the 30 day trailing fee rate. Currently it assumes 
  # the highest taker fee rate of 0.30%.
  def maker_taker(_exchange_id, _account_id) do
    maker = Decimal.new(0)
    taker = Decimal.new(0.003)

    {:ok, {maker, taker}}
  end
end
