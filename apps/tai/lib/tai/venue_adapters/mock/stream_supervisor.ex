defmodule Tai.VenueAdapters.Mock.StreamSupervisor do
  use Supervisor

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
      {Tai.VenueAdapters.Mock.Stream.Connection,
       [
         url: url(),
         venue_id: venue_id,
         channels: channels,
         account: accounts |> Map.to_list() |> List.first(),
         products: products
       ]}
    ]

    (order_books ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  # TODO: Make this configurable
  defp url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws"
end
