defmodule Tai.AdvisorResponders.MarketQuote do
  alias Tai.AdvisorResponders.Responder
  @behaviour Responder

  @impl Responder
  def respond({response, state}, {:order_book_changes, venue_id, product_symbol, changes}) do
    previous_inside_quote =
      state.market_quotes |> Tai.Advisors.MarketQuotes.for(venue_id, product_symbol)

    new_state =
      if inside_quote_is_stale?(previous_inside_quote, changes) do
        cache_inside_quote(state, venue_id, product_symbol)
      else
        state
      end

    new_quote = new_state.market_quotes |> Tai.Advisors.MarketQuotes.for(venue_id, product_symbol)
    new_reseponse = Map.put(response, :market_quote, new_quote)

    {:ok, {new_reseponse, new_state}}
  end

  def respond({response, state}, {:order_book_snapshot, venue_id, product_symbol, _snapshot}) do
    new_state = cache_inside_quote(state, venue_id, product_symbol)
    new_quote = new_state.market_quotes |> Tai.Advisors.MarketQuotes.for(venue_id, product_symbol)
    new_reseponse = Map.put(response, :market_quote, new_quote)
    {:ok, {new_reseponse, new_state}}
  end

  defp cache_inside_quote(state, venue_id, product_symbol) do
    {:ok, current_inside_quote} = Tai.Markets.OrderBook.inside_quote(venue_id, product_symbol)
    key = {venue_id, product_symbol}
    old_market_quotes = state.market_quotes
    updated_market_quotes_data = Map.put(old_market_quotes.data, key, current_inside_quote)
    updated_market_quotes = Map.put(old_market_quotes, :data, updated_market_quotes_data)

    state
    |> Map.put(:market_quotes, updated_market_quotes)
  end

  defp inside_quote_is_stale?(previous_inside_quote, %Tai.Markets.OrderBook{
         bids: bids,
         asks: asks
       }) do
    (bids |> Enum.any?() && bids |> inside_bid_is_stale?(previous_inside_quote)) ||
      (asks |> Enum.any?() && asks |> inside_ask_is_stale?(previous_inside_quote))
  end

  defp inside_bid_is_stale?(_bids, nil), do: true

  defp inside_bid_is_stale?(bids, %Tai.Markets.Quote{} = prev_quote) do
    bids
    |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
      price >= prev_quote.bid.price ||
        (price == prev_quote.bid.price && size != prev_quote.bid.size)
    end)
  end

  defp inside_ask_is_stale?(_asks, nil), do: true

  defp inside_ask_is_stale?(asks, %Tai.Markets.Quote{} = prev_quote) do
    asks
    |> Enum.any?(fn {price, {size, _processed_at, _server_changed_at}} ->
      price <= prev_quote.ask.price ||
        (price == prev_quote.ask.price && size != prev_quote.ask.size)
    end)
  end
end
