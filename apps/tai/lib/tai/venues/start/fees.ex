defmodule Tai.Venues.Start.Fees do
  @type venue :: Tai.Venue.t()
  @type product :: Tai.Venues.Product.t()

  @spec hydrate(venue, [product]) :: :ok | {:error, reason :: term}
  def hydrate(venue, products) do
    {venue, products}
    |> fetch
    |> build
    |> store
  end

  defp fetch({venue, products}) do
    venue.credentials
    |> Map.keys()
    |> Enum.map(fn credential_id ->
      try do
        response = Tai.Venues.Client.maker_taker_fees(venue, credential_id)
        {response, credential_id}
      rescue
        e ->
          {{:error, {e, __STACKTRACE__}}, credential_id}
      end
    end)
    |> Enum.reduce(
      {:ok, []},
      fn
        {{:ok, credential_fee_schedule}, credential_id}, {:ok, fee_schedules} ->
          {:ok, fee_schedules ++ [{credential_fee_schedule, credential_id}]}

        {{:error, reason}, credential_id}, {:ok, _} ->
          {:error, [{credential_id, reason}]}

        {{:error, reason}, credential_id}, {:error, reasons} ->
          {:error, reasons ++ [{credential_id, reason}]}
      end
    )
    |> case do
      {:ok, fees} -> {:ok, venue, products, fees}
      {:error, _reasons} = error -> error
    end
  end

  defp build({:ok, venue, products, fee_schedules}) do
    fees =
      products
      |> Enum.flat_map(fn p ->
        fee_schedules
        |> Enum.map(fn
          {{_maker, _taker}, _credential_id} = f -> f
          {nil, credential_id} -> {{nil, nil}, credential_id}
        end)
        |> Enum.map(fn {{maker, taker}, credential_id} ->
          %Tai.Venues.FeeInfo{
            venue_id: venue.id,
            credential_id: credential_id,
            symbol: p.symbol,
            maker: lowest_fee(p.maker_fee, maker),
            maker_type: :percent,
            taker: lowest_fee(p.taker_fee, taker),
            taker_type: :percent
          }
        end)
      end)

    {:ok, fees}
  end

  defp build({:error, _} = error) do
    error
  end

  defp store({:ok, fees} = result) do
    Enum.each(fees, &Tai.Venues.FeeStore.upsert(&1))
    result
  end

  defp store({:error, _} = error) do
    error
  end

  defp lowest_fee(%Decimal{} = product, %Decimal{} = schedule), do: Decimal.min(product, schedule)
  defp lowest_fee(nil, %Decimal{} = schedule), do: schedule
  defp lowest_fee(%Decimal{} = product, nil), do: product
end
