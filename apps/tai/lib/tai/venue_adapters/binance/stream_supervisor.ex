defmodule Tai.VenueAdapters.Binance.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.Binance.Stream.{
    Connection,
    ProcessOptionalChannels,
    ProcessOrderBook,
    RouteOrderBooks
  }

  alias Tai.Markets.{OrderBook, ProcessQuote}

  @type adapter :: Tai.Venues.Adapter.t()
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(venue_adapter: adapter, products: [product]) :: Supervisor.on_start()
  def start_link([venue_adapter: venue_adapter, products: _] = args) do
    name = venue_adapter.id |> to_name()
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  # TODO: Make this configurable
  @base_url "wss://stream.binance.com:9443/stream"

  def init(venue_adapter: venue_adapter, products: products) do
    account = venue_adapter.accounts |> Map.to_list() |> List.first()

    market_quote_children = market_quote_children(products)
    order_book_children = order_book_children(products)
    process_order_book_children = process_order_book_children(products)

    system = [
      {RouteOrderBooks, [venue_id: venue_adapter.id, products: products]},
      {ProcessOptionalChannels, [venue_id: venue_adapter.id]},
      {Connection,
       [
         url: url(products, venue_adapter.channels),
         venue_id: venue_adapter.id,
         account: account,
         products: products
       ]}
    ]

    (market_quote_children ++ order_book_children ++ process_order_book_children ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp url(products, channels) do
    streams =
      (build_depth_url_segments(products) ++ build_trade_url_segments(channels, products))
      |> Enum.join("/")

    "#{@base_url}?streams=#{streams}"
  end

  defp build_depth_url_segments(products) do
    products
    |> build_venue_symbols
    |> Enum.map(&"#{&1}@depth")
  end

  @optional_channels ~w(trades)a
  defp build_trade_url_segments(channels, products) do
    channels
    |> Enum.filter(&Enum.member?(@optional_channels, &1))
    |> Enum.map(fn
      :trades ->
        products
        |> build_venue_symbols
        |> Enum.map(&"#{&1}@trade")
    end)
    |> List.flatten()
  end

  defp build_venue_symbols(products) do
    products
    |> Enum.map(& &1.venue_symbol)
    |> Enum.map(&String.downcase/1)
  end

  defp market_quote_children(products) do
    products
    |> Enum.map(fn p ->
      %{
        id: ProcessQuote.to_name(p.venue_id, p.symbol),
        start: {ProcessQuote, :start_link, [p]}
      }
    end)
  end

  defp order_book_children(products) do
    products
    |> Enum.map(fn p ->
      %{
        id: OrderBook.to_name(p.venue_id, p.symbol),
        start: {OrderBook, :start_link, [p]}
      }
    end)
  end

  defp process_order_book_children(products) do
    products
    |> Enum.map(fn p ->
      %{
        id: ProcessOrderBook.to_name(p.venue_id, p.venue_symbol),
        start: {ProcessOrderBook, :start_link, [p]}
      }
    end)
  end
end
