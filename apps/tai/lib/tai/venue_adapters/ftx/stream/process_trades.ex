defmodule Tai.VenueAdapters.Ftx.Stream.ProcessTrades do
  use GenServer

  defmodule State do
    @type venue :: Tai.Venue.id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type venue_products :: %{String.t() => product_symbol}
    @type t :: %State{venue: venue, venue_products: venue_products}

    @enforce_keys ~w[venue venue_products]a
    defstruct ~w[venue venue_products]a
  end

  @type venue :: Tai.Venue.id()
  @type state :: State.t()

  def start_link(venue: venue, products: products) do
    venue_products = products |> build_venue_products()
    state = %State{venue: venue, venue_products: venue_products}
    name = venue |> process_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec process_name(venue) :: atom
  def process_name(venue) do
    :"#{__MODULE__}_#{venue}"
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(
    {%{"channel" => "trades", "type" => "update", "market" => venue_product_symbol, "data" => data}, received_at},
    state
  ) do
    publish_trades(venue_product_symbol, data, received_at, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast(
    {%{"channel" => "trades", "type" => "subscribed"}, _received_at},
    state
  ) do
    {:noreply, state}
  end

  defp build_venue_products(products) do
    products
    |> Enum.reduce(
      %{},
      fn p, acc ->
        Map.put(acc, p.venue_symbol, p.symbol)
      end
    )
  end

  defp publish_trades(venue_product_symbol, data, received_at, state) do
    data
    |> Enum.each(fn data ->
      qty = data |> Map.fetch!("size") |> Tai.Utils.Decimal.cast!()
      price = data |> Map.fetch!("price") |> Tai.Utils.Decimal.cast!()
      {:ok, venue_timestamp, _} = data |> Map.fetch!("time") |> DateTime.from_iso8601()
      product_symbol = Map.fetch!(state.venue_products, venue_product_symbol)

      trade = %Tai.Markets.Trade{
        venue: state.venue,
        product_symbol: product_symbol,
        id: Map.fetch!(data, "id"),
        price: price,
        qty: qty,
        liquidation: Map.fetch!(data, "liquidation"),
        side: Map.fetch!(data, "side"),
        venue_timestamp: venue_timestamp,
        received_at: received_at
      }

      Tai.Markets.publish_trade(trade)
    end)
  end
end
