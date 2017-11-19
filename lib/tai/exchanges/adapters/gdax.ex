defmodule Tai.Exchanges.Adapters.Gdax do
  def balance do
    ExGdax.list_accounts
    |> case do
      {:ok, accounts} ->
        accounts
        |> Enum.map(
          fn(%{"balance" => balance}) ->
            balance
            |> Float.parse
            |> case do
              {parsed, _remainder} -> Decimal.new(parsed)
            end
          end
        )
    end
    |> Tai.Currency.sum
  end
end
