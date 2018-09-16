defmodule Tai.ExchangeAdapters.Gdax.HydrateProducts do
  use GenServer

  def start_link([exchange_id: exchange_id, whitelist_query: _] = state) do
    name = :"#{__MODULE__}_#{exchange_id}"
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state) do
    {:ok, state, {:continue, :fetch}}
  end

  def handle_continue(:fetch, state) do
    fetch!(state)
    {:noreply, state}
  end

  defp fetch!(exchange_id: exchange_id, whitelist_query: query) do
    with {:ok, exchange_products} <- ExGdax.list_products() do
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
      fn %{"base_currency" => base_asset, "quote_currency" => quote_asset} = info, acc ->
        symbol = Tai.Symbol.build(base_asset, quote_asset)
        Map.put(acc, symbol, {exchange_id, info})
      end
    )
  end

  defp upsert_product({
         symbol,
         {
           exchange_id,
           %{
             "id" => id,
             "status" => exchange_status,
             "base_min_size" => raw_base_min_size,
             "base_max_size" => raw_base_max_size,
             "quote_increment" => raw_quote_increment
           }
         }
       }) do
    with status <- tai_status(exchange_status),
         base_min_size <- Decimal.new(raw_base_min_size),
         base_max_size <- Decimal.new(raw_base_max_size),
         quote_increment <- Decimal.new(raw_quote_increment),
         min_notional <- Decimal.mult(base_min_size, quote_increment) do
      %Tai.Exchanges.Product{
        exchange_id: exchange_id,
        symbol: symbol,
        exchange_symbol: id,
        status: status,
        min_notional: min_notional,
        min_price: quote_increment,
        min_size: base_min_size,
        max_size: base_max_size,
        price_increment: quote_increment,
        size_increment: base_min_size
      }
      |> Tai.Exchanges.Products.upsert()
    end
  end

  defp tai_status("online"), do: :trading
end
