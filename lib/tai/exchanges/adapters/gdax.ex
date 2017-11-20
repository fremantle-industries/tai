defmodule Tai.Exchanges.Adapters.Gdax do
  def price(symbol) do
    symbol
    |> product_id
    |> ExGdax.get_ticker
    |> case do
      {:ok, %{"price" => price}} ->
        price
        |> Decimal.new
    end
  end

  def balance do
    ExGdax.list_accounts
    |> parse_account_balances
    |> convert_account_balances_to_usd
    |> Tai.Currency.sum
  end

  def quotes(symbol, start \\ Timex.now) do
    symbol
    |> product_id
    |> ExGdax.get_order_book
    |> case do
      {
        :ok,
        %{
          "bids" => [[bid_price, bid_size, _bid_order_count]],
          "asks" => [[ask_price, ask_size, _ask_order_count]]
        }
      } ->
        age = Decimal.new(Timex.diff(Timex.now, start) / 1_000_000)
        {
          %Tai.Quote{
            size: Decimal.new(bid_size),
            price: Decimal.new(bid_price),
            age: age
          },
          %Tai.Quote{
            size: Decimal.new(ask_size),
            price: Decimal.new(ask_price),
            age: age
          }
        }
    end
  end

  def buy_limit(symbol, price, size) do
    %{
      "type" => "limit",
      "side" => "buy",
      "product_id" => symbol |> product_id,
      "price" => price |> Float.to_string,
      "size" => size |> Float.to_string
    }
    |> ExGdax.create_order
    |> case do
      {:ok, %{"id" => id, "status" => status}} ->
        {:ok, %Tai.OrderResponse{id: id, status: status |> parse_order_status}}
      {:error, message, _status_code} ->
        {:error, message}
    end
  end

  defp parse_account_balances(response) do
    case response do
      {:ok, accounts} ->
        accounts
        |> Enum.map(
          fn(%{"currency" => currency, "balance" => balance}) ->
            balance
            |> Decimal.new
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

  def parse_order_status(status) do
    case status do
      "pending" -> :pending
    end
  end
end
