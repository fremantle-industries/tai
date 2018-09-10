defmodule Tai.ExchangeAdapters.Binance.HydrateFees do
  use Tai.Exchanges.HydrateFees

  def maker_taker(_exchange_id, _account_id) do
    {
      :ok,
      %Binance.Account{
        maker_commission: maker_commission,
        taker_commission: taker_commission
      }
    } = Binance.get_account()

    percent_factor = Decimal.new(10_000)
    maker = maker_commission |> Decimal.new() |> Decimal.div(percent_factor)
    taker = taker_commission |> Decimal.new() |> Decimal.div(percent_factor)

    {:ok, {maker, taker}}
  end
end
