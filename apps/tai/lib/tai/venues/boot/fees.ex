defmodule Tai.Venues.Boot.Fees do
  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()

  @spec hydrate(venue, [product]) :: :ok | {:error, reason :: term}
  def hydrate(venue, products) do
    venue.accounts
    |> Enum.map(&fee_schedules(&1, venue))
    |> Enum.reduce(:ok, &upsert_for_account(&1, &2, venue.id, products))
  end

  defp fee_schedules({account_id, _}, venue) do
    schedule_result = Tai.Venues.Client.maker_taker_fees(venue, account_id)
    {schedule_result, account_id}
  end

  defp upsert_for_account({{:ok, schedule}, account_id}, :ok, venue_id, products) do
    Enum.each(
      products,
      &upsert_product(&1, venue_id, account_id, schedule)
    )

    :ok
  end

  defp upsert_for_account({{:error, _} = error, _}, _, _, _), do: error

  defp upsert_product(product, venue_id, account_id, {maker, taker}) do
    lowest_maker = lowest_fee(product.maker_fee, maker)
    lowest_taker = lowest_fee(product.taker_fee, taker)
    upsert_product(product, venue_id, account_id, lowest_maker, lowest_taker)
  end

  defp upsert_product(product, venue_id, account_id, nil) do
    upsert_product(product, venue_id, account_id, product.maker_fee, product.taker_fee)
  end

  defp upsert_product(product, venue_id, account_id, maker, taker) do
    %Tai.Venues.FeeInfo{
      venue_id: venue_id,
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
