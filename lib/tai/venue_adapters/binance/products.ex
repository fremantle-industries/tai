defmodule Tai.VenueAdapters.Binance.Products do
  def products(venue_id) do
    with {:ok, %Binance.ExchangeInfo{symbols: exchange_products}} <- Binance.get_exchange_info() do
      products = Enum.map(exchange_products, &build(&1, venue_id))
      {:ok, products}
    else
      {:error, %{"code" => -2014, "msg" => "API-key format invalid." = reason}} ->
        {:error, %Tai.CredentialError{reason: reason}}

      {:error, {:http_error, %HTTPoison.Error{reason: "timeout"}}} ->
        {:error, %Tai.TimeoutError{}}
    end
  end

  defp build(
         %{
           "baseAsset" => base_asset,
           "quoteAsset" => quote_asset,
           "symbol" => exchange_symbol,
           "status" => exchange_status,
           "filters" => filters
         },
         venue_id
       ) do
    {:ok, status} = Tai.VenueAdapters.Binance.ProductStatus.normalize(exchange_status)
    {min_price, max_price, tick_size} = filters |> price_filter
    {min_size, max_size, step_size} = filters |> size_filter
    %Decimal{} = min_notional = filters |> notional_filter

    %Tai.Exchanges.Product{
      exchange_id: venue_id,
      symbol: Tai.Symbol.build(base_asset, quote_asset),
      exchange_symbol: exchange_symbol,
      status: status,
      min_notional: min_notional,
      min_price: min_price,
      min_size: min_size,
      price_increment: tick_size,
      max_price: max_price,
      max_size: max_size,
      size_increment: step_size
    }
  end

  @price_filter "PRICE_FILTER"
  defp price_filter(filters) do
    with %{"minPrice" => min, "maxPrice" => max, "tickSize" => tick} <-
           find_filter(filters, @price_filter) do
      {Decimal.new(min), Decimal.new(max), Decimal.new(tick)}
    end
  end

  @size_filter "LOT_SIZE"
  defp size_filter(filters) do
    with %{"minQty" => min, "maxQty" => max, "stepSize" => step} <-
           find_filter(filters, @size_filter) do
      {Decimal.new(min), Decimal.new(max), Decimal.new(step)}
    end
  end

  @notional_filter "MIN_NOTIONAL"
  defp notional_filter(filters) do
    with %{"minNotional" => notional} <- find_filter(filters, @notional_filter) do
      Decimal.new(notional)
    end
  end

  defp find_filter(filters, type) do
    filters
    |> Enum.find(fn f -> f["filterType"] == type end)
  end
end
