defmodule Tai.Markets.ProcessQuote do
  use GenServer
  alias Tai.Markets.{Quote, PricePoint}

  defmodule State do
    @type market_quote :: Tai.Markets.Quote.t()
    @type t :: %State{
            market_quote: market_quote | nil,
            depth: pos_integer
          }

    @enforce_keys ~w(market_quote depth)a
    defstruct ~w(market_quote depth)a
  end

  @type venue_id :: Tai.Venue.id()
  @type product :: Tai.Venues.Product.t()
  @type product_symbol :: Tai.Venues.Product.symbol()

  @spec start_link(product: product, depth: pos_integer) :: GenServer.on_start()
  def start_link(product: product, depth: depth) when depth > 0 do
    state = %State{market_quote: nil, depth: depth}
    name = product.venue_id |> to_name(product.symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, product_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  def init(state), do: {:ok, state}

  def handle_cast({:order_book_snapshot, order_book, change_set}, state) do
    new_market_quote = build_market_quote(order_book, change_set, state.depth)
    new_state = state |> Map.put(:market_quote, new_market_quote)
    {:noreply, new_state, {:continue, :put_market_quote}}
  end

  def handle_cast({:order_book_apply, order_book, change_set}, state) do
    new_market_quote = build_market_quote(order_book, change_set, state.depth)

    if market_quote_changed?(state.market_quote, new_market_quote) do
      new_state = state |> Map.put(:market_quote, new_market_quote)
      {:noreply, new_state, {:continue, :put_market_quote}}
    else
      {:noreply, state}
    end
  end

  def handle_continue(:put_market_quote, state) do
    Tai.Markets.QuoteStore.put(state.market_quote)
    {:noreply, state}
  end

  defp build_market_quote(order_book, change_set, depth) do
    bids = price_points(order_book.bids, depth, &(&1 > &2))
    asks = price_points(order_book.asks, depth, &(&1 < &2))

    %Quote{
      venue_id: order_book.venue_id,
      product_symbol: order_book.product_symbol,
      last_venue_timestamp: change_set.last_venue_timestamp,
      last_received_at: change_set.last_received_at,
      bids: bids,
      asks: asks
    }
  end

  defp price_points(side, depth, sort_by) do
    side
    |> Map.keys()
    |> Enum.sort(sort_by)
    |> Enum.take(depth)
    |> Enum.map(&%PricePoint{price: &1, size: side |> Map.fetch!(&1)})
  end

  defp market_quote_changed?(nil, %Quote{}), do: true

  defp market_quote_changed?(current_market_quote, new_market_quote) do
    inside_price_point_changed?(current_market_quote.bids, new_market_quote.bids) ||
      inside_price_point_changed?(current_market_quote.asks, new_market_quote.asks)
  end

  defp inside_price_point_changed?(current, new) do
    current |> List.first() != new |> List.first()
  end
end
