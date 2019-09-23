defmodule Tai.VenueAdapters.Gdax.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.Gdax.Stream.{
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
    name = venue_id |> to_name()
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  # TODO: Make this configurable
  @endpoint "wss://ws-feed.pro.coinbase.com/"

  def init(
        venue_id: venue,
        channels: channels,
        accounts: accounts,
        products: products,
        opts: opts
      ) do
    order_books = build_order_books(products)
    order_book_stores = build_order_book_stores(products)

    system = [
      {RouteOrderBooks, [venue_id: venue, products: products]},
      {ProcessOptionalChannels, [venue_id: venue]},
      {Connection,
       [
         url: @endpoint,
         venue: venue,
         channels: channels,
         account: accounts |> Map.to_list() |> List.first(),
         products: products,
         opts: opts
       ]}
    ]

    (order_books ++ order_book_stores ++ system)
    |> Supervisor.init(strategy: :one_for_one)
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
        start: {
          ProcessOrderBook,
          :start_link,
          [[venue_id: p.venue_id, symbol: p.symbol, venue_symbol: p.venue_symbol]]
        }
      }
    end)
  end
end
