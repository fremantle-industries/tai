defmodule Tai.VenueAdapters.Binance.StreamSupervisor do
  use Supervisor

  @type product :: Tai.Venues.Product.t()

  @spec start_link(venue_id: atom, accounts: map, products: [product]) :: Supervisor.on_start()
  def start_link([venue_id: venue_id, accounts: _, products: _] = args) do
    Supervisor.start_link(__MODULE__, args, name: :"#{__MODULE__}_#{venue_id}")
  end

  # TODO: Make this configurable
  @base_url "wss://stream.binance.com:9443/stream"

  def init(venue_id: venue_id, accounts: accounts, products: products) do
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

    system = [
      {Tai.VenueAdapters.Binance.Stream.ProcessOrderBooks,
       [venue_id: venue_id, products: products]},
      {Tai.VenueAdapters.Binance.Stream.ProcessMessages, [venue_id: venue_id]},
      {Tai.VenueAdapters.Binance.Stream.Connection,
       [
         url: products |> url(),
         venue_id: venue_id,
         account: accounts |> Map.to_list() |> List.first(),
         products: products
       ]}
    ]

    (order_books ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp url(products) do
    streams =
      products
      |> Enum.map(& &1.symbol)
      |> Enum.map(&Tai.ExchangeAdapters.Binance.SymbolMapping.to_binance/1)
      |> Enum.map(&String.downcase/1)
      |> Enum.map(&"#{&1}@depth")
      |> Enum.join("/")

    "#{@base_url}?streams=#{streams}"
  end
end
