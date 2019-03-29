defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBooks do
  use GenServer
  require Logger
  alias Tai.VenueAdapters.Binance.Stream

  defmodule State do
    @type t :: %State{venue_id: atom, venue_products: map}

    @enforce_keys ~w(venue_id venue_products)a
    defstruct ~w(venue_id venue_products)a
  end

  def start_link(venue_id: venue_id, products: products) do
    state = %State{
      venue_id: venue_id,
      venue_products: products |> to_venue_products()
    }

    GenServer.start_link(__MODULE__, state, name: venue_id |> to_name())
  end

  def init(state), do: {:ok, state}

  @spec to_name(venue_id :: atom) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_cast(
        {%{
           "data" => %{
             "e" => "depthUpdate",
             "E" => event_time,
             "s" => venue_symbol,
             "U" => _first_update_id_in_event,
             "u" => _final_update_id_in_event,
             "b" => changed_bids,
             "a" => changed_asks
           },
           "stream" => _stream_name
         }, received_at},
        state
      ) do
    {:ok, venue_sent_at} = DateTime.from_unix(event_time, :millisecond)
    symbol = state.venue_products |> Map.fetch!(venue_symbol)
    bids = changed_bids |> Stream.DepthUpdate.normalize(received_at, venue_sent_at)
    asks = changed_asks |> Stream.DepthUpdate.normalize(received_at, venue_sent_at)

    %Tai.Markets.OrderBook{
      venue_id: state.venue_id,
      product_symbol: symbol,
      bids: bids,
      asks: asks
    }
    |> Tai.Markets.OrderBook.update()

    {:noreply, state}
  end

  defp to_venue_products(products) do
    products
    |> Enum.reduce(
      %{},
      fn p, acc -> Map.put(acc, p.exchange_symbol, p.symbol) end
    )
  end
end
