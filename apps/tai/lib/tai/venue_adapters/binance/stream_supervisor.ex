defmodule Tai.VenueAdapters.Binance.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.Binance.Stream.{
    Connection,
    ProcessOptionalChannels,
    ProcessOrderBook,
    RouteOrderBooks
  }

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type channel :: Tai.Venues.Adapter.channel()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(
          venue_id: venue_id,
          channels: [channel],
          accounts: map,
          products: [product],
          opts: map
        ) ::
          Supervisor.on_start()
  def start_link([venue_id: venue_id, channels: _, accounts: _, products: _, opts: _] = args) do
    Supervisor.start_link(__MODULE__, args, name: :"#{__MODULE__}_#{venue_id}")
  end

  # TODO: Make this configurable
  @base_url "wss://stream.binance.com:9443/stream"

  def init(venue_id: venue, channels: channels, accounts: accounts, products: products, opts: _) do
    order_books = build_order_books(products)
    order_book_stores = build_order_book_stores(products)

    system = [
      {RouteOrderBooks, [venue_id: venue, products: products]},
      {ProcessOptionalChannels, [venue_id: venue]},
      {Connection,
       [
         url: url(products, channels),
         venue_id: venue,
         account: accounts |> Map.to_list() |> List.first(),
         products: products
       ]}
    ]

    (order_books ++ order_book_stores ++ system)
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

  defp build_order_books(products) do
    products
    |> Enum.map(fn p ->
      %{
        id: Tai.Markets.OrderBook.to_name(p.venue_id, p.symbol),
        start: {Tai.Markets.OrderBook, :start_link, [p]}
      }
    end)
  end

  defp build_order_book_stores(products) do
    products
    |> Enum.map(fn p ->
      %{
        id: ProcessOrderBook.to_name(p.venue_id, p.venue_symbol),
        start: {ProcessOrderBook, :start_link, [p]}
      }
    end)
  end
end
