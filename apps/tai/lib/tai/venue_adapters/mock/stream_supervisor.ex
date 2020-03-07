defmodule Tai.VenueAdapters.Mock.StreamSupervisor do
  use Supervisor
  alias Tai.Markets.OrderBook

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()

  @spec start_link(stream) :: Supervisor.on_start()
  def start_link(stream) do
    name = stream.venue.id |> to_name()
    Supervisor.start_link(__MODULE__, stream, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def init(stream) do
    credential = stream.venue.credentials |> Map.to_list() |> List.first()

    order_book_children =
      order_book_children(
        stream.products,
        stream.venue.quote_depth,
        stream.venue.broadcast_change_set
      )

    system = [
      {Tai.VenueAdapters.Mock.Stream.Connection,
       [
         url: url(),
         venue_id: stream.venue.id,
         channels: stream.venue.channels,
         credentials: credential,
         products: stream.products
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
