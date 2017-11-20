defmodule Tai.Exchanges.Adapters.Gdax do
  def price(symbol) do
    symbol
    |> product_id
    |> ExGdax.get_ticker
    |> case do
      {:ok, %{"price" => price}} ->
        price
        |> Tai.Currency.parse!
    end
  end

  def balance do
    ExGdax.list_accounts
    |> parse_account_balances
    |> convert_account_balances_to_usd
    |> Tai.Currency.sum
  end

  defp parse_account_balances(response) do
    case response do
      {:ok, accounts} ->
        accounts
        |> Enum.map(
          fn(%{"currency" => currency, "balance" => balance}) ->
            balance
            |> Tai.Currency.parse!
            |> (&{currency, &1}).()
          end
        )
    end
  end

  defp convert_account_balances_to_usd(balances) do
    balances
    |> Enum.map(
      fn({currency, balance}) ->
        case currency do
          "USD" -> balance
          "BTC" -> Decimal.mult(balance, price(:btcusd))
          "ETH" -> Decimal.mult(balance, price(:ethusd))
          "LTC" -> Decimal.mult(balance, price(:ltcusd))
        end
      end
    )
  end

  defp product_id(symbol) do
    ExGdax.list_products
    |> case do
      {:ok, products} ->
        products
        |> Enum.map(fn(%{"id" => id}) -> id end)
        |> Enum.find(&match_product(symbol, &1))
    end
  end

  def match_product(symbol, product_id) do
    symbol
    |> Atom.to_string
    |> String.downcase
    ==
    product_id
    |> String.replace("-", "")
    |> String.downcase
  end
end
