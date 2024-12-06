defmodule Tai.VenueAdapters.Binance.Products do
  def products(venue_id) do
    with {:ok, %ExBinance.ExchangeInfo{symbols: venue_products}} <-
           ExBinance.Spot.Public.exchange_info() do
      products = Enum.map(venue_products, &build(&1, venue_id))
      {:ok, products}
    else
      {:error, {:binance_error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}}} ->
        {:error, {:credentials, reason}}

      {:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}} ->
        {:error, :timeout}
    end
  end

  defp build(
         %{
           "baseAsset" => base_asset,
           "quoteAsset" => quote_asset,
           "symbol" => venue_symbol,
           "status" => exchange_status,
           "filters" => filters
         },
         venue_id
       ) do
    symbol = Tai.Symbol.build(base_asset, quote_asset)
    {:ok, status} = Tai.VenueAdapters.Binance.ProductStatus.normalize(exchange_status)
    {min_price, max_price, tick_size} = filters |> price_filter
    {min_size, max_size, step_size} = filters |> size_filter

    min_notional =
      case filters |> notional_filter do
        nil -> %Decimal{}
        %Decimal{} = res -> res
      end

    %Tai.Venues.Product{
      venue_id: venue_id,
      symbol: symbol,
      venue_symbol: venue_symbol,
      base: base_asset |> downcase_and_atom(),
      quote: quote_asset |> downcase_and_atom(),
      venue_base: base_asset,
      venue_quote: quote_asset,
      status: status,
      type: :spot,
      collateral: false,
      price_increment: tick_size,
      size_increment: step_size,
      min_price: min_price,
      min_size: min_size,
      min_notional: min_notional,
      max_price: max_price,
      max_size: max_size,
      value: Decimal.new(1),
      value_side: :base,
      is_quanto: false,
      is_inverse: false
    }
  end

  defp downcase_and_atom(str), do: str |> String.downcase() |> String.to_atom()

  @price_filter "PRICE_FILTER"
  defp price_filter(filters) do
    with %{"minPrice" => min, "maxPrice" => max, "tickSize" => tick} <-
           find_filter(filters, @price_filter) do
      {
        min |> to_decimal(),
        max |> to_decimal(),
        tick |> to_decimal()
      }
    end
  end

  @size_filter "LOT_SIZE"
  defp size_filter(filters) do
    with %{"minQty" => min, "maxQty" => max, "stepSize" => step} <-
           find_filter(filters, @size_filter) do
      {
        min |> to_decimal(),
        max |> to_decimal(),
        step |> to_decimal()
      }
    end
  end

  @notional_filter "MIN_NOTIONAL"
  defp notional_filter(filters) do
    with %{"minNotional" => notional} <- find_filter(filters, @notional_filter) do
      notional |> to_decimal()
    end
  end

  defp find_filter(filters, type) do
    filters
    |> Enum.find(fn f -> f["filterType"] == type end)
  end

  defp to_decimal(val), do: val |> Decimal.new() |> Decimal.normalize()
end
