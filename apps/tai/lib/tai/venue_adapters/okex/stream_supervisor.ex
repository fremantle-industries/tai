defmodule Tai.VenueAdapters.OkEx.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.OkEx.Stream.{
    Connection,
    ProcessAuth,
    ProcessOptionalChannels,
    ProcessOrderBook,
    RouteOrderBooks
  }

  alias Tai.Markets.OrderBook

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()

  @spec start_link(stream) :: Supervisor.on_start()
  def start_link(stream) do
    name = to_name(stream.venue.id)
    Supervisor.start_link(__MODULE__, stream, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  # TODO: Make this configurable
  @endpoint "wss://real.okex.com:8443/ws/v3"

  def init(stream) do
    credential = stream.venue.credentials |> Map.to_list() |> List.first()

    order_book_children =
      order_book_children(
        stream.products,
        stream.venue.quote_depth,
        stream.venue.broadcast_change_set
      )

    process_order_book_children = process_order_book_children(stream.products)

    system = [
      {RouteOrderBooks, [venue: stream.venue.id, products: stream.products]},
      {ProcessAuth, [venue: stream.venue.id]},
      {ProcessOptionalChannels, [venue: stream.venue.id]},
      {Connection,
       [
         endpoint: @endpoint,
         venue: stream.venue.id,
         channels: stream.venue.channels,
         credential: credential,
         products: stream.products
       ]}
    ]

    (order_book_children ++ process_order_book_children ++ system)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp order_book_children(products, quote_depth, broadcast_change_set) do
    products
    |> Enum.map(&OrderBook.child_spec(&1, quote_depth, broadcast_change_set))
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
