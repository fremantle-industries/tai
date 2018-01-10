defmodule Tai.Exchanges.Config do
  def exchanges do
    Application.get_env(:tai, :exchanges)
  end

  def exchange_ids do
    exchanges()
    |> Enum.map(fn {id, _config} -> id end)
  end

  def exchange_adapter(name) do
    exchanges()
    |> Map.fetch!(name)
  end

  def order_book_feeds do
    Application.get_env(:tai, :order_book_feeds)
  end

  def order_book_feed_ids do
    order_book_feeds()
    |> Enum.reduce(
      [],
      fn {feed_id, _config}, acc ->
        Enum.concat(acc, [feed_id])
      end
    )
  end

  def order_book_feed_adapters do
    order_book_feeds()
    |> Enum.reduce(
      %{},
      fn {feed_id, [adapter: adapter, order_books: _]}, acc ->
        Map.put(acc, feed_id, adapter)
      end
    )
  end

  def order_book_feed_adapter(feed_id) do
    order_book_feed_adapters()
    |> Map.fetch!(feed_id)
  end

  def order_book_feed_symbols(feed_id) do
    order_book_feeds()
    |> Enum.reduce(
      %{},
      fn {feed_id, [adapter: _, order_books: order_books]}, acc ->
        Map.put(acc, feed_id, order_books)
      end
    )
    |> Map.fetch!(feed_id)
  end
end
