defmodule Tai.ExchangeAdapters.Gdax.Products do
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
    with {:ok, products} <- ExGdax.list_products() do
      Enum.each(products, &upsert_product(&1, exchange_id))
      Tai.Boot.fetched_products(exchange_id)
    end
  end

  defp upsert_product(
         %{
           "id" => id,
           "base_currency" => base_asset,
           "quote_currency" => quote_asset,
           "status" => exchange_status,
           "base_min_size" => raw_base_min_size,
           "base_max_size" => raw_base_max_size,
           "quote_increment" => raw_quote_increment
         },
         exchange_id
       ) do
    with symbol <- Tai.Symbol.build(base_asset, quote_asset),
         status <- tai_status(exchange_status),
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
        price_increment: quote_increment,
        max_size: base_max_size
      }
      |> Tai.Exchanges.Products.upsert()
    end
  end

  defp tai_status("online"), do: :trading
end
