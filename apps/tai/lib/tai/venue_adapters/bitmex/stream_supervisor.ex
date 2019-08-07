defmodule Tai.VenueAdapters.Bitmex.StreamSupervisor do
  use Supervisor

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
  @url "wss://" <> ExBitmex.Rest.HTTPClient.domain() <> "/realtime"

  def init(
        venue_id: venue_id,
        channels: channels,
        accounts: accounts,
        products: products,
        opts: _
      ) do
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
          id: Tai.VenueAdapters.Bitmex.Stream.OrderBookStore.to_name(venue_id, p.venue_symbol),
          start: {
            Tai.VenueAdapters.Bitmex.Stream.OrderBookStore,
            :start_link,
            [[venue_id: venue_id, symbol: p.symbol, venue_symbol: p.venue_symbol]]
          }
        }
      end)

    system = [
      {Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBooks,
       [venue_id: venue_id, products: products]},
      {Tai.VenueAdapters.Bitmex.Stream.ProcessAuth, [venue_id: venue_id]},
      {Tai.VenueAdapters.Bitmex.Stream.ProcessMessages, [venue_id: venue_id]},
      {Tai.VenueAdapters.Bitmex.Stream.Connection,
       [
         url: @url,
         venue: venue_id,
         channels: channels,
         account: accounts |> Map.to_list() |> List.first(),
         products: products
       ]}
    ]

    (order_books ++ order_book_stores ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
