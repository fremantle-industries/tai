defmodule Tai.ExchangeAdapters.Binance.Products do
  use GenServer

  def start_link(exchange_id) do
    GenServer.start_link(
      __MODULE__,
      exchange_id,
      name: :"#{__MODULE__}_#{exchange_id}"
    )
  end

  def init(exchange_id) do
    {:ok, exchange_id, 0}
  end

  def handle_info(:timeout, exchange_id) do
    fetch!(exchange_id)
    {:noreply, exchange_id}
  end

  defp fetch!(exchange_id) do
    with {:ok, %Binance.ExchangeInfo{symbols: symbols}} <- Binance.get_exchange_info() do
      Enum.each(symbols, &upsert_product(&1, exchange_id))
      Tai.Boot.fetched_products(exchange_id)
    end
  end

  defp upsert_product(
         %{
           "symbol" => exchange_symbol,
           "status" => exchange_status,
           "baseAsset" => base_asset,
           "quoteAsset" => quote_asset,
           "filters" => filters
         },
         exchange_id
       ) do
    with symbol <- Tai.Symbol.build(base_asset, quote_asset),
         status <- tai_status(exchange_status),
         {min_price, max_price, tick_size} <- filters |> price_filter,
         {min_size, max_size, step_size} <- filters |> size_filter do
      %Tai.Exchanges.Product{
        exchange_id: exchange_id,
        symbol: symbol,
        exchange_symbol: exchange_symbol,
        status: status,
        min_price: min_price,
        max_price: max_price,
        tick_size: tick_size,
        min_size: min_size,
        max_size: max_size,
        step_size: step_size
      }
      |> Tai.Exchanges.Products.upsert()
    end
  end

  defp tai_status("TRADING"), do: :trading

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

  defp find_filter(filters, type) do
    filters
    |> Enum.find(fn f -> f["filterType"] == type end)
  end
end
