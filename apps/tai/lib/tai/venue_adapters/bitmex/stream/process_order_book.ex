defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBook do
  use GenServer

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type product_symbol :: Tai.Venues.Product.symbol()
    @type t :: %State{
            venue_id: venue_id,
            symbol: product_symbol,
            table: %{optional(String.t()) => number}
          }

    @enforce_keys ~w(venue_id symbol table)a
    defstruct ~w(venue_id symbol table)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product :: Tai.Venues.Product.t()
  @type venue_symbol :: Tai.Venues.Product.venue_symbol()
  @type state :: State.t()

  @spec start_link(product) :: GenServer.on_start()
  def start_link(product) do
    state = %State{venue_id: product.venue_id, symbol: product.symbol, table: %{}}
    name = to_name(product.venue_id, product.venue_symbol)

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id, venue_symbol) :: atom
  def to_name(venue, symbol), do: :"#{__MODULE__}_#{venue}_#{symbol}"

  @spec init(state) :: {:ok, state}
  def init(state), do: {:ok, state}

  def handle_cast({:snapshot, data, received_at}, state) do
    normalized_data =
      data
      |> Enum.reduce(
        %{changes: [], table: %{}},
        fn
          %{"id" => id, "price" => price, "side" => "Sell", "size" => size}, acc ->
            changes = [{:upsert, :ask, price, size} | acc.changes]
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:changes, changes)
            |> Map.put(:table, table)

          %{"id" => id, "price" => price, "side" => "Buy", "size" => size}, acc ->
            changes = [{:upsert, :bid, price, size} | acc.changes]
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:changes, changes)
            |> Map.put(:table, table)
        end
      )

    %Tai.Markets.OrderBook.ChangeSet{
      venue: state.venue_id,
      symbol: state.symbol,
      last_received_at: received_at,
      changes: normalized_data.changes
    }
    |> Tai.Markets.OrderBook.replace()

    new_table = Map.merge(state.table, normalized_data.table)
    new_state = Map.put(state, :table, new_table)

    {:noreply, new_state}
  end

  def handle_cast({:insert, data, received_at}, state) do
    normalized_data =
      data
      |> Enum.reduce(
        %{changes: [], table: %{}},
        fn
          %{"id" => id, "price" => price, "side" => "Sell", "size" => size}, acc ->
            changes = [{:upsert, :ask, price, size} | acc.changes]
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:changes, changes)
            |> Map.put(:table, table)

          %{"id" => id, "price" => price, "side" => "Buy", "size" => size}, acc ->
            changes = [{:upsert, :bid, price, size} | acc.changes]
            table = acc.table |> Map.put(id, price)

            acc
            |> Map.put(:changes, changes)
            |> Map.put(:table, table)
        end
      )

    %Tai.Markets.OrderBook.ChangeSet{
      venue: state.venue_id,
      symbol: state.symbol,
      last_received_at: received_at,
      changes: normalized_data.changes |> Enum.reverse()
    }
    |> Tai.Markets.OrderBook.apply()

    new_table = Map.merge(state.table, normalized_data.table)
    new_state = Map.put(state, :table, new_table)

    {:noreply, new_state}
  end

  def handle_cast({:update, data, received_at}, state) do
    changes =
      data
      |> Enum.reduce(
        [],
        fn
          %{"id" => id, "side" => "Sell", "size" => size}, acc ->
            price = Map.fetch!(state.table, id)
            [{:upsert, :ask, price, size} | acc]

          %{"id" => id, "side" => "Buy", "size" => size}, acc ->
            price = Map.fetch!(state.table, id)
            [{:upsert, :bid, price, size} | acc]
        end
      )

    %Tai.Markets.OrderBook.ChangeSet{
      venue: state.venue_id,
      symbol: state.symbol,
      last_received_at: received_at,
      changes: changes |> Enum.reverse()
    }
    |> Tai.Markets.OrderBook.apply()

    {:noreply, state}
  end

  def handle_cast({:delete, data, received_at}, state) do
    normalized_data =
      data
      |> Enum.reduce(
        %{changes: [], table: []},
        fn
          %{"id" => id, "side" => "Sell"}, acc ->
            price = Map.fetch!(state.table, id)
            changes = [{:delete, :ask, price} | acc.changes]
            table = [id | acc.table]

            acc
            |> Map.put(:changes, changes)
            |> Map.put(:table, table)

          %{"id" => id, "side" => "Buy"}, acc ->
            price = Map.fetch!(state.table, id)
            changes = [{:delete, :bid, price} | acc.changes]
            table = [id | acc.table]

            acc
            |> Map.put(:changes, changes)
            |> Map.put(:table, table)
        end
      )

    %Tai.Markets.OrderBook.ChangeSet{
      venue: state.venue_id,
      symbol: state.symbol,
      last_received_at: received_at,
      changes: normalized_data.changes |> Enum.reverse()
    }
    |> Tai.Markets.OrderBook.apply()

    new_table = Map.drop(state.table, normalized_data.table)
    new_state = Map.put(state, :table, new_table)

    {:noreply, new_state}
  end
end
