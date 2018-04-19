defmodule Tai.Exchanges.Config do
  @moduledoc """
  Configuration helper for exchanges
  """

  @doc """
  Return a map of exchange configuration

  ## Examples

    iex> Tai.Exchanges.Config.exchanges
    %{
      test_exchange_a: [
        supervisor: Tai.ExchangeAdapters.Test.Supervisor
      ],
      test_exchange_b: [
        supervisor: Tai.ExchangeAdapters.Test.Supervisor
      ]
    }
  """
  def exchanges do
    Application.get_env(:tai, :exchanges)
  end

  @doc """
  Return a keyword list of the configured exchange id & supervisor

  ## Examples

    iex> Tai.Exchanges.Config.exchange_supervisors
    [
      test_exchange_a: Tai.ExchangeAdapters.Test.Supervisor,
      test_exchange_b: Tai.ExchangeAdapters.Test.Supervisor
    ]
  """
  def exchange_supervisors do
    exchanges()
    |> Enum.map(fn {exchange_id, config} ->
      {exchange_id, Keyword.get(config, :supervisor)}
    end)
  end

  @doc """
  Return the keys for the exchange adapters

  ## Examples

    iex> Tai.Exchanges.Config.exchange_ids()
    [:test_exchange_a, :test_exchange_b]
  """
  def exchange_ids do
    for {id, _} <- exchanges(), do: id
  end

  @doc """
  Return a map of order book feed adapters and the books to subscribe to

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feeds()
    %{
      test_feed_a: [
        adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
        order_books: [:btcusd, :ltcusd]
      ],
      test_feed_b: [
        adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
        order_books: [:ethusd, :ltcusd]
      ]
    }
  """
  def order_book_feeds do
    Application.get_env(:tai, :order_book_feeds)
  end

  @doc """
  Return athe keys for the order book feed adapters

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feed_ids()
    [:test_feed_a, :test_feed_b]
  """
  def order_book_feed_ids do
    order_book_feeds()
    |> Enum.reduce([], fn {feed_id, _config}, acc ->
      Enum.concat(acc, [feed_id])
    end)
  end

  @doc """
  Return a map of the order book feed adapters keyed by their id

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feed_adapters()
    %{
      test_feed_a: Tai.ExchangeAdapters.Test.OrderBookFeed,
      test_feed_b: Tai.ExchangeAdapters.Test.OrderBookFeed
    }
  """
  def order_book_feed_adapters do
    order_book_feeds()
    |> Enum.reduce(%{}, fn {feed_id, [adapter: adapter, order_books: _]}, acc ->
      Map.put(acc, feed_id, adapter)
    end)
  end

  @doc """
  Return the module for the order book feed adapter id

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feed_adapter(:test_feed_a)
    Tai.ExchangeAdapters.Test.OrderBookFeed
  """
  def order_book_feed_adapter(feed_id) do
    order_book_feed_adapters()
    |> Map.fetch!(feed_id)
  end

  @doc """
  Return the order book symbols that are configured for the feed id

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feed_symbols(:test_feed_a)
    [:btcusd, :ltcusd]
  """
  def order_book_feed_symbols(feed_id) do
    order_book_feeds()
    |> Enum.reduce(%{}, fn {feed_id, [adapter: _, order_books: order_books]}, acc ->
      Map.put(acc, feed_id, order_books)
    end)
    |> Map.fetch!(feed_id)
  end
end
