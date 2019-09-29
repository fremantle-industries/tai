defmodule Tai.VenueAdapters.Mock.StreamSupervisor do
  use Supervisor
  alias Tai.Markets.{OrderBook, ProcessQuote}

  @type channel :: Tai.Venues.Adapter.channel()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(
          venue_id: atom,
          channels: [channel],
          accounts: map,
          products: [product],
          opts: map
        ) ::
          Supervisor.on_start()
  def start_link([venue_id: venue_id, channels: _, accounts: _, products: _, opts: _] = args) do
    Supervisor.start_link(__MODULE__, args, name: :"#{__MODULE__}_#{venue_id}")
  end

  def init(
        venue_id: venue_id,
        channels: channels,
        accounts: accounts,
        products: products,
        opts: _
      ) do
    account = accounts |> Map.to_list() |> List.first()

    market_quote_children = market_quote_children(products)
    order_book_children = order_book_children(products)

    system = [
      {Tai.VenueAdapters.Mock.Stream.Connection,
       [
         url: url(),
         venue_id: venue_id,
         channels: channels,
         account: account,
         products: products
       ]}
    ]

    (market_quote_children ++ order_book_children ++ system)
    |> Supervisor.init(strategy: :one_for_one)
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

  # TODO: Make this configurable
  defp url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws"
end
