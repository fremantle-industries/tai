defmodule Tai.VenueAdapters.OkEx.StreamSupervisor do
  use Supervisor
  alias Tai.VenueAdapters.OkEx.Stream

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(venue_id: atom, accounts: map, products: [product]) :: Supervisor.on_start()
  def start_link([venue_id: venue_id, accounts: _, products: _] = args) do
    Supervisor.start_link(__MODULE__, args, name: :"#{__MODULE__}_#{venue_id}")
  end

  # TODO: Make this configurable
  @endpoint "wss://real.okex.com:10442/ws/v3"

  def init(venue_id: venue_id, accounts: _accounts, products: products) do
    # TODO: Potentially this could use new order books? Send the change quote 
    # event to subscribing advisors?
    order_books =
      products
      |> Enum.map(fn p ->
        name = Tai.Markets.OrderBook.to_name(venue_id, p.symbol)

        %{
          id: name,
          start: {
            Tai.Markets.OrderBook,
            :start_link,
            [[feed_id: venue_id, symbol: p.symbol]]
          }
        }
      end)

    order_book_stores =
      products
      |> Enum.map(fn p ->
        %{
          id: Stream.OrderBookStore.to_name(venue_id, p.venue_symbol),
          start: {
            Stream.OrderBookStore,
            :start_link,
            [[venue_id: venue_id, symbol: p.symbol, venue_symbol: p.venue_symbol]]
          }
        }
      end)

    system = [
      {Stream.ProcessOrderBooks, [venue: venue_id, products: products]},
      {Tai.VenueAdapters.OkEx.Stream.ProcessMessages, [venue: venue_id]},
      {Stream.Connection,
       [
         endpoint: @endpoint,
         venue: venue_id,
         account: nil,
         products: products
       ]}
    ]

    (order_books ++ order_book_stores ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
