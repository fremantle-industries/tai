defmodule Tai.Exchanges.Boot.Fees do
  @type adapter :: Tai.Exchanges.Adapter.t()
  @type product :: Tai.Exchanges.Product.t()

  @spec hydrate(adapter :: adapter, products :: [product]) :: :ok | {:error, reason :: term}
  def hydrate(adapter, products) do
    adapter.accounts
    |> Enum.reduce(
      :ok,
      &fetch_and_upsert(&1, &2, adapter, products)
    )
  end

  defp fetch_and_upsert({account_id, _}, :ok, adapter, products) do
    with {:ok, {maker, taker}} <- Tai.Exchanges.Exchange.maker_taker_fees(adapter, account_id) do
      products
      |> Enum.each(fn product ->
        %Tai.Exchanges.FeeInfo{
          exchange_id: adapter.id,
          account_id: account_id,
          symbol: product.symbol,
          maker: maker,
          maker_type: Tai.Exchanges.FeeInfo.percent(),
          taker: taker,
          taker_type: Tai.Exchanges.FeeInfo.percent()
        }
        |> Tai.Exchanges.FeeStore.upsert()
      end)

      :ok
    else
      {:error, _} = error ->
        error
    end
  end

  defp fetch_and_upsert({_, _}, {:error, _} = error, _, _), do: error
end
