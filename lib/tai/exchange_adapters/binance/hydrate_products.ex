defmodule Tai.ExchangeAdapters.Binance.HydrateProducts do
  use GenServer

  def start_link([exchange_id: _, whitelist_query: _] = state) do
    GenServer.start_link(
      __MODULE__,
      state,
      name: state |> to_name
    )
  end

  def init(state) do
    {:ok, state, 0}
  end

  def handle_info(:timeout, state) do
    fetch!(state)
    {:noreply, state}
  end

  defp to_name(exchange_id: exchange_id, whitelist_query: _) do
    :"#{__MODULE__}_#{exchange_id}"
  end

  defp fetch!(exchange_id: exchange_id, whitelist_query: query) do
    with {:ok, %Binance.ExchangeInfo{symbols: exchange_products}} <- Binance.get_exchange_info() do
      exchange_products
      |> index_by_symbol(exchange_id)
      |> Juice.squeeze(query)
      |> Enum.each(&upsert_product/1)

      Tai.Boot.fetched_products(exchange_id)
    end
  end

  defp index_by_symbol(exchange_products, exchange_id) do
    exchange_products
    |> Enum.reduce(
      %{},
      fn %{"baseAsset" => base_asset, "quoteAsset" => quote_asset} = info, acc ->
        symbol = Tai.Symbol.build(base_asset, quote_asset)
        Map.put(acc, symbol, {exchange_id, info})
      end
    )
  end

  defp upsert_product({
         symbol,
         {
           exchange_id,
           %{"symbol" => exchange_symbol, "status" => exchange_status, "filters" => filters}
         }
       }) do
    with {:ok, status} <- Tai.ExchangeAdapters.Binance.ProductStatus.tai_status(exchange_status),
         {min_price, max_price, tick_size} <- filters |> price_filter,
         {min_size, max_size, step_size} <- filters |> size_filter,
         %Decimal{} = min_notional <- filters |> notional_filter do
      %Tai.Exchanges.Product{
        exchange_id: exchange_id,
        symbol: symbol,
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
      |> Tai.Exchanges.ProductStore.upsert()
    end
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
