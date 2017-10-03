defmodule Tai.Currency do
  def add(balance_a, balance_b, symbol) do
    case symbol |> adapter do
      {:ok, currency} -> currency.add(balance_a, balance_b)
      {:error, error} -> {:error, error}
    end
  end

  def sum(enumerable, symbol) do
    Enum.reduce(enumerable, 0.0, fn(val, accumulator) ->
      add(val, accumulator, symbol)
    end)
  end

  defp adapter(symbol) do
    case symbol do
      :btc -> {:ok, Tai.Currencies.Bitcoin}
      :ltc -> {:ok, Tai.Currencies.Litecoin}
      _ -> {:error, :unknown_symbol, symbol}
    end
  end
end
