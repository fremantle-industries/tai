defmodule Tai.VenueAdapters.Poloniex.MakerTakerFees do
  def maker_taker_fees(_venue_id, _account_id, _credentials) do
    with {:ok, %{"makerFee" => maker_fee, "takerFee" => taker_fee}} <-
           ExPoloniex.Trading.return_fee_info() do
      maker = maker_fee |> to_decimal()
      taker = taker_fee |> to_decimal()
      {:ok, {maker, taker}}
    else
      {:error, %ExPoloniex.AuthenticationError{} = reason} ->
        {:error, {:credentials, reason}}

      {:error, %HTTPoison.Error{reason: "timeout"}} ->
        {:error, :timeout}
    end
  end

  defp to_decimal(fee), do: fee |> Decimal.new() |> Decimal.reduce()
end
