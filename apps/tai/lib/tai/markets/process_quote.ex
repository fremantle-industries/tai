defmodule Tai.Markets.ProcessQuote do
  use GenServer
  alias Tai.Markets.{Quote, PricePoint}

  defmodule State do
    @type market_quote :: Tai.Markets.Quote.t()
    @type t :: %State{market_quote: market_quote | nil}

    @enforce_keys ~w(market_quote)a
    defstruct ~w(market_quote)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()
  @type product_symbol :: Tai.Venues.Product.symbol()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    state = %State{market_quote: nil}
    name = product.venue_id |> to_name(product.symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, product_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  def init(state), do: {:ok, state}

  def handle_cast({:order_book_snapshot, order_book, change_set}, state) do
    new_market_quote = market_quote(order_book, change_set)
    new_state = state |> Map.put(:market_quote, new_market_quote)

    {:noreply, new_state, {:continue, :broadcast_market_quote}}
  end

  def handle_cast({:order_book_apply, order_book, change_set}, state) do
    new_market_quote = market_quote(order_book, change_set)

    if (!state.market_quote && new_market_quote) ||
         new_market_quote.bid != state.market_quote.bid ||
         new_market_quote.ask != state.market_quote.ask do
      new_state = state |> Map.put(:market_quote, new_market_quote)
      {:noreply, new_state, {:continue, :broadcast_market_quote}}
    else
      {:noreply, state}
    end
  end

  def handle_continue(:broadcast_market_quote, state) do
    msg = {:tai, state.market_quote}

    {:market_quote, state.market_quote.venue_id, state.market_quote.product_symbol}
    |> Tai.PubSub.broadcast(msg)

    :market_quote
    |> Tai.PubSub.broadcast(msg)

    {:noreply, state}
  end

  defp market_quote(order_book, change_set) do
    bid_price = inside_price(order_book.bids, &(&1 > &2))
    bid_price_point = price_point(order_book.bids, bid_price)
    ask_price = inside_price(order_book.asks, &(&1 < &2))
    ask_price_point = price_point(order_book.asks, ask_price)

    %Quote{
      venue_id: order_book.venue_id,
      product_symbol: order_book.product_symbol,
      last_venue_timestamp: change_set.last_venue_timestamp,
      last_received_at: change_set.last_received_at,
      bid: bid_price_point,
      ask: ask_price_point
    }
  end

  defp inside_price(side, sort_by) do
    side
    |> Map.keys()
    |> Enum.sort(sort_by)
    |> List.first()
  end

  defp price_point(_side, nil), do: nil
  defp price_point(side, price), do: %PricePoint{price: price, size: side |> Map.fetch!(price)}
end
