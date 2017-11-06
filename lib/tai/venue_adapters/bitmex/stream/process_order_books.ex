defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBooks do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream

  @type t :: %Stream.ProcessOrderBooks{
          venue_id: atom,
          exchange_products: map
        }

  @enforce_keys [:venue_id, :exchange_products]
  defstruct [:venue_id, :exchange_products]

  def start_link(venue_id: venue_id, products: products) do
    exchange_products =
      products
      |> Enum.reduce(
        %{},
        fn p, acc -> Map.put(acc, p.exchange_symbol, p.symbol) end
      )

    state = %Stream.ProcessOrderBooks{
      venue_id: venue_id,
      exchange_products: exchange_products
    }

    GenServer.start_link(__MODULE__, state, name: venue_id |> to_name())
  end

  def init(state), do: {:ok, state}

  @spec to_name(venue_id :: atom) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_cast({%{"request" => _}, _received_at}, state) do
    {:noreply, state}
  end

  def handle_cast(
        {
          %{
            "action" => "partial",
            "filter" => %{"symbol" => bitmex_symbol},
            "data" => data
          },
          received_at
        },
        state
      ) do
    state.venue_id
    |> Stream.OrderBookStore.to_name(bitmex_symbol)
    |> GenServer.cast({:snapshot, data, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"action" => "insert", "data" => [%{"symbol" => bitmex_symbol} | _] = data},
          received_at
        },
        state
      ) do
    state.venue_id
    |> Stream.OrderBookStore.to_name(bitmex_symbol)
    |> GenServer.cast({:insert, data, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"action" => "update", "data" => [%{"symbol" => bitmex_symbol} | _] = data},
          received_at
        },
        state
      ) do
    state.venue_id
    |> Stream.OrderBookStore.to_name(bitmex_symbol)
    |> GenServer.cast({:update, data, received_at})

    {:noreply, state}
  end

  def handle_cast(
        {
          %{"action" => "delete", "data" => [%{"symbol" => bitmex_symbol} | _] = data},
          received_at
        },
        state
      ) do
    state.venue_id
    |> Stream.OrderBookStore.to_name(bitmex_symbol)
    |> GenServer.cast({:delete, data, received_at})

    {:noreply, state}
  end
end
