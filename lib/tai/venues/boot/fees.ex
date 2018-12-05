defmodule Tai.Venues.Boot.Fees do
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()

  @spec hydrate(adapter :: adapter, products :: [product]) :: :ok | {:error, reason :: term}
  def hydrate(adapter, products) do
    adapter.accounts
    |> Enum.map(&fee_schedules(&1, adapter))
    |> Enum.reduce(:ok, &upsert_for_account(&1, &2, adapter.id, products))
  end

  defp fee_schedules({account_id, _}, adapter) do
    schedule_result = Tai.Venue.maker_taker_fees(adapter, account_id)
    {schedule_result, account_id}
  end

  defp upsert_for_account({{:ok, schedule}, account_id}, :ok, adapter_id, products) do
    Enum.each(
      products,
      &upsert_product(&1, adapter_id, account_id, schedule)
    )

    :ok
  end

  defp upsert_for_account({{:error, _} = error, _}, _, _, _), do: error

  defp upsert_product(product, adapter_id, account_id, {maker, taker}) do
    lowest_maker = lowest_fee(product.maker_fee, maker)
    lowest_taker = lowest_fee(product.taker_fee, taker)
    upsert_product(product, adapter_id, account_id, lowest_maker, lowest_taker)
  end

  defp upsert_product(product, adapter_id, account_id, nil) do
    upsert_product(product, adapter_id, account_id, product.maker_fee, product.taker_fee)
  end

  defp upsert_product(product, adapter_id, account_id, maker, taker) do
    %Tai.Venues.FeeInfo{
      exchange_id: adapter_id,
      account_id: account_id,
      symbol: product.symbol,
      maker: maker,
      maker_type: :percent,
      taker: taker,
      taker_type: :percent
    }
    |> Tai.Venues.FeeStore.upsert()
  end

  defp lowest_fee(%Decimal{} = product, %Decimal{} = schedule), do: Decimal.min(product, schedule)
  defp lowest_fee(nil, %Decimal{} = schedule), do: schedule
end
