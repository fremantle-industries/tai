defmodule Tai.ExchangeAdapters.New.Binance.MakerTakerFees do
  def maker_taker_fees(_exchange_id, _account_id, _credentials) do
    with {:ok, %Binance.Account{} = account} <- Binance.get_account() do
      percent_factor = Decimal.new(10_000)
      maker = account.maker_commission |> Decimal.new() |> Decimal.div(percent_factor)
      taker = account.taker_commission |> Decimal.new() |> Decimal.div(percent_factor)
      {:ok, {maker, taker}}
    else
      {:error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}} ->
        {:error, %Tai.TimeoutError{reason: "network request timed out"}}
    end
  end
end
