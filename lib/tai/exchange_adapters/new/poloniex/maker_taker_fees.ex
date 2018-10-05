defmodule Tai.ExchangeAdapters.New.Poloniex.MakerTakerFees do
  def maker_taker_fees(_exchange_id, _account_id, _credentials) do
    with {:ok, %{"makerFee" => maker_fee, "takerFee" => taker_fee}} <-
           ExPoloniex.Trading.return_fee_info() do
      maker = Decimal.new(maker_fee)
      taker = Decimal.new(taker_fee)
      {:ok, {maker, taker}}
    else
      {:error, %ExPoloniex.AuthenticationError{} = reason} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, %HTTPoison.Error{reason: "timeout"}} ->
        {:error, %Tai.TimeoutError{reason: "network request timed out"}}
    end
  end
end
