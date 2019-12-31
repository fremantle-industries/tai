defmodule Tai.VenueAdapters.Gdax.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.Gdax.Stream.{
    Connection,
    ProcessOptionalChannels,
    ProcessOrderBook,
    RouteOrderBooks
  }

  alias Tai.Markets.{OrderBook, ProcessQuote}

  @type venue :: Tai.Venue.t()
  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(venue: venue, products: [product]) :: Supervisor.on_start()
  def start_link([venue: venue, products: _] = args) do
    name = venue.id |> to_name()
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  # TODO: Make this configurable
  @endpoint "wss://ws-feed.pro.coinbase.com/"

  def init(venue: venue, products: products) do
    credential = venue.credentials |> Map.to_list() |> List.first()

    market_quote_children = market_quote_children(products, venue.quote_depth)
    order_book_children = order_book_children(products)
    process_order_book_children = process_order_book_children(products)

    system = [
      {RouteOrderBooks, [venue_id: venue.id, products: products]},
      {ProcessOptionalChannels, [venue_id: venue.id]},
      {Connection,
       [
         url: @endpoint,
         venue: venue.id,
         channels: venue.channels,
         credential: credential,
         products: products,
         opts: venue.opts
       ]}
    ]

    (market_quote_children ++ order_book_children ++ process_order_book_children ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp market_quote_children(products, depth) do
    products
    |> Enum.map(fn p ->
      %{
        id: ProcessQuote.to_name(p.venue_id, p.symbol),
        start: {ProcessQuote, :start_link, [[product: p, depth: depth]]}
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
