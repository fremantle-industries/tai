defmodule Tai.Exchanges.Config do
  @moduledoc """
  Configuration helper for exchanges
  """

  @doc """
  Return a map of account configuration

  ## Examples

    iex> Tai.Exchanges.Config.accounts
    %{
      test_account_a: [
        adapter: Tai.ExchangeAdapters.Test.Account
      ],
      test_account_b: [
        adapter: Tai.ExchangeAdapters.Test.Account
      ]
    }
  """
  def accounts do
    Application.get_env(:tai, :accounts)
  end

  @doc """
  Return the keys for the account adapters

  ## Examples

    iex> Tai.Exchanges.Config.account_ids()
    [:test_account_a, :test_account_b]
  """
  def account_ids do
    for {id, _} <- accounts(), do: id
  end

  @doc """

  ## Examples

    iex> Tai.Exchanges.Config.account_adapter(:test_account_a)
    Tai.ExchangeAdapters.Test.Account
  """
  def account_adapter(account_id) do
    accounts()
    |> Map.get(account_id)
    |> Keyword.get(:adapter)
  end

  @doc """
  Return a map of order book feed adapters and the books to subscribe to

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feeds()
    %{
      test_feed_a: [
        adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
        order_books: [:btc_usd, :ltc_usd]
      ],
      test_feed_b: [
        adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
        order_books: [:eth_usd, :ltc_usd]
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
    [:btc_usd, :ltc_usd]
  """
  def order_book_feed_symbols(feed_id) do
    order_book_feeds()
    |> Enum.reduce(%{}, fn {feed_id, [adapter: _, order_books: order_books]}, acc ->
      Map.put(acc, feed_id, order_books)
    end)
    |> Map.fetch!(feed_id)
  end
end
