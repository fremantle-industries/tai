defmodule Tai.ExchangeAdapters.Mock.HydrateFees do
  use Tai.Exchanges.HydrateFees

  def maker_taker(_exchange_id, _account_id) do
    maker = Decimal.new(0.1)
    taker = Decimal.new(0.1)

    {:ok, {maker, taker}}
  end
end
