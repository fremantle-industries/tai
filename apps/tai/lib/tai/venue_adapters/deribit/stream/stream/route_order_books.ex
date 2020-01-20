defmodule Tai.VenueAdapters.Deribit.Stream.RouteOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.Deribit.Stream.ProcessOrderBook

  defmodule State do
    @type venue :: Tai.Venue.id()
    @type venue_symbol :: Tai.Venues.Product.venue_symbol()
    @type store_name :: atom
    @type stores :: %{optional(venue_symbol) => store_name}
    @type t :: %State{venue: venue, stores: stores}

    @enforce_keys ~w(venue stores)a
    defstruct ~w(venue stores)a
  end

  @type venue :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()

  @spec start_link(venue_id: venue, products: [product]) :: GenServer.on_start()
  def start_link(venue_id: venue, products: products) do
    stores = products |> build_stores(venue)
    state = %State{venue: venue, stores: stores}
    name = venue |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def init(state), do: {:ok, state}

  def handle_cast(
        {
          %{
            "params" => %{
              "channel" => "book." <> _channel,
              "data" =>
                %{
                  "instrument_name" => venue_symbol
                } = data
            }
          },
          received_at
        },
        state
      ) do
    {state, venue_symbol}
    |> forward({:update, data, received_at})

    {:noreply, state}
  end

  defp build_stores(products, venue_id) do
    products
    |> Enum.reduce(
      %{},
      &Map.put(&2, &1.venue_symbol, venue_id |> ProcessOrderBook.to_name(&1.venue_symbol))
    )
  end

  defp forward({state, venue_symbol}, msg) do
    state.stores
    |> Map.fetch!(venue_symbol)
    |> GenServer.cast(msg)
  end
end
