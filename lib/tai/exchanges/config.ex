defmodule Tai.Exchanges.Config do
  @moduledoc """
  Configuration helper for exchanges
  """

  @type t :: %Tai.Exchanges.Config{}

  @enforce_keys [:id, :supervisor]
  defstruct id: nil, supervisor: nil, products: "*", accounts: %{}

  @doc """
  Return a struct for all configured exchanges 

  ## Examples

    iex> Tai.Exchanges.Config.all
    [
      %Tai.Exchanges.Config{
        id: :test_exchange_a,
        supervisor: Tai.ExchangeAdapters.Mock.Supervisor,
        products: "*",
        accounts: %{main: %{}}
      },
      %Tai.Exchanges.Config{
        id: :test_exchange_b,
        supervisor: Tai.ExchangeAdapters.Mock.Supervisor,
        products: "*",
        accounts: %{main: %{}}
      }
    ]
  """
  @spec all :: [t]
  def all(exchanges \\ Application.get_env(:tai, :exchanges)) do
    exchanges
    |> Enum.map(fn {id, params} ->
      %Tai.Exchanges.Config{
        id: id,
        supervisor: Keyword.get(params, :supervisor),
        products: Keyword.get(params, :products, "*"),
        accounts: Keyword.get(params, :accounts, %{})
      }
    end)
  end

  @doc """
  Return a map of order book feed adapters and the books to subscribe to

  ## Examples

    iex> Tai.Exchanges.Config.order_book_feeds()
    %{
      test_feed_a: [
        adapter: Tai.ExchangeAdapters.Mock.OrderBookFeed,
        order_books: [:btc_usd, :ltc_usd]
      ],
      test_feed_b: [
        adapter: Tai.ExchangeAdapters.Mock.OrderBookFeed,
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
      test_feed_a: Tai.ExchangeAdapters.Mock.OrderBookFeed,
      test_feed_b: Tai.ExchangeAdapters.Mock.OrderBookFeed
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
    Tai.ExchangeAdapters.Mock.OrderBookFeed
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
