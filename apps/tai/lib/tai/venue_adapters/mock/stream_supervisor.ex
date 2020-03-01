defmodule Tai.VenueAdapters.Mock.StreamSupervisor do
  use Supervisor
  alias Tai.Markets.OrderBook

  @type venue :: Tai.Venue.t()
  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type account :: Tai.Venues.Account.t()

  @spec start_link(venue: venue, products: [product], accounts: [account]) ::
          Supervisor.on_start()
  def start_link([venue: venue, products: _, accounts: _] = args) do
    name = venue.id |> to_name()
    Supervisor.start_link(__MODULE__, args, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def init(venue: venue, products: products, accounts: _) do
    credential = venue.credentials |> Map.to_list() |> List.first()

    order_book_children =
      order_book_children(products, venue.quote_depth, venue.broadcast_change_set)

    system = [
      {Tai.VenueAdapters.Mock.Stream.Connection,
       [
         url: url(),
         venue_id: venue.id,
         channels: venue.channels,
         credentials: credential,
         products: products
       ]}
    ]

    (order_book_children ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp order_book_children(products, quote_depth, broadcast_change_set) do
    products
    |> Enum.map(&OrderBook.child_spec(&1, quote_depth, broadcast_change_set))
  end

  # TODO: Make this configurable
  defp url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws"
end
