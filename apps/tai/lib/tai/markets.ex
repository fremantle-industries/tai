defmodule Tai.Markets do
  @type market_quote :: Tai.Markets.Quote.t()
  @type trade :: Tai.Markets.Trade.t()
  @type venue :: Tai.Venue.id()
  @type product_symbol :: Tai.Venues.Product.symbol()

  @trade_topic_prefix "trade"
  @spec publish_trade(trade) :: [:ok | {:error, term}]
  def publish_trade(trade) do
    [
      "#{@trade_topic_prefix}:*",
      "#{@trade_topic_prefix}:#{trade.venue}",
      "#{@trade_topic_prefix}:#{trade.venue},#{trade.product_symbol}"
    ]
    |> Enum.map(& broadcast(&1, trade))
  end

  @spec subscribe_trade(String.t() | venue | {venue, product_symbol}) :: :ok | {:error, term}
  def subscribe_trade("*"), do: subscribe("#{@trade_topic_prefix}:*")
  def subscribe_trade({venue, product_symbol}), do: subscribe("#{@trade_topic_prefix}:#{venue},#{product_symbol}")
  def subscribe_trade(venue), do: subscribe("#{@trade_topic_prefix}:#{venue}")

  @quote_topic_prefix "quote"
  @spec publish_quote(market_quote) :: [:ok | {:error, term}]
  def publish_quote(market_quote) do
    [
      "#{@quote_topic_prefix}:*",
      "#{@quote_topic_prefix}:#{market_quote.venue_id}",
      "#{@quote_topic_prefix}:#{market_quote.venue_id},#{market_quote.product_symbol}"
    ]
    |> Enum.map(& broadcast(&1, market_quote))
  end

  @spec subscribe_quote(String.t() | venue | {venue, product_symbol}) :: :ok | {:error, term}
  def subscribe_quote("*"), do: subscribe("#{@quote_topic_prefix}:*")
  def subscribe_quote({venue, product_symbol}), do: subscribe("#{@quote_topic_prefix}:#{venue},#{product_symbol}")
  def subscribe_quote(venue), do: subscribe("#{@quote_topic_prefix}:#{venue}")

  defp broadcast(topic, msg) do
    Phoenix.PubSub.broadcast(Tai.PubSub, topic, msg)
  end

  defp subscribe(topic) do
    Phoenix.PubSub.subscribe(Tai.PubSub, topic)
  end
end
