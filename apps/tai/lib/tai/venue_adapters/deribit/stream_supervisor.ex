defmodule Tai.VenueAdapters.Deribit.StreamSupervisor do
  use Supervisor

  alias Tai.VenueAdapters.Deribit.Stream.{
    Connection
  }

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
  @endpoint "wss://#{ExDeribit.HTTPClient.domain()}/ws#{ExDeribit.HTTPClient.api_path()}"

  def init(venue: venue, products: products) do
    credential = venue.credentials |> Map.to_list() |> List.first()

    system = [
      {Connection,
       [
         url: @endpoint,
         venue: venue.id,
         channels: venue.channels,
         credential: credential,
         products: products,
         quote_depth: venue.quote_depth,
         opts: venue.opts
       ]}
    ]

    system
    |> Supervisor.init(strategy: :one_for_one)
  end
end
