defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case, async: true
  alias Tai.Markets.{OrderBook, PricePoint, Quote}

  @venue Tai.Markets.OrderBookTest

  defmodule Subscriber do
    use GenServer

    @venue Tai.Markets.OrderBookTest

    def start_link(_), do: GenServer.start_link(__MODULE__, :ok)
    def init(state), do: {:ok, state}

    def subscribe_to_order_book_snapshot do
      Tai.PubSub.subscribe({:order_book_snapshot, @venue, :btc_usd})
    end

    def subscribe_to_order_book_changes do
      Tai.PubSub.subscribe({:order_book_changes, @venue, :btc_usd})
    end

    def handle_info({:order_book_snapshot, _, _, _} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end

    def handle_info({:order_book_changes, _, _, _} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    book_pid = start_supervised!({OrderBook, venue: @venue, symbol: :btc_usd})

    %{book_pid: book_pid}
  end

  describe ".replace" do
    test "overrides the bids & asks", %{book_pid: book_pid} do
      :ok =
        OrderBook.replace(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{
            999.9 => 1.1,
            999.8 => 1.0
          },
          asks: %{
            1000.0 => 0.1,
            1000.1 => 0.11
          }
        })

      {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)

      assert Enum.count(bids) == 2
      assert Enum.at(bids, 0) == %PricePoint{price: 999.9, size: 1.1}
      assert Enum.at(bids, 1) == %PricePoint{price: 999.8, size: 1.0}

      assert Enum.count(asks) == 2
      assert Enum.at(asks, 0) == %PricePoint{price: 1000.0, size: 0.1}
      assert Enum.at(asks, 1) == %PricePoint{price: 1000.1, size: 0.11}
    end

    test "broadcasts a pubsub event" do
      start_supervised!(Subscriber)
      Subscriber.subscribe_to_order_book_snapshot()

      :ok =
        OrderBook.replace(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{999.9 => 1.1},
          asks: %{1000.0 => 0.1}
        })

      assert_receive {
        :order_book_snapshot,
        venue,
        :btc_usd,
        snapshot
      }

      assert venue == @venue

      assert %OrderBook{
               bids: %{999.9 => 1.1},
               asks: %{1000.0 => 0.1}
             } = snapshot
    end
  end

  describe ".update" do
    test "changes the given bids and asks", %{book_pid: book_pid} do
      :ok =
        OrderBook.update(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{
            147.52 => 10.1,
            147.53 => 10.3
          },
          asks: %{
            150.01 => 1.1,
            150.00 => 1.3
          }
        })

      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)

      assert Enum.count(bids) == 2
      assert Enum.at(bids, 0) == %PricePoint{price: 147.53, size: 10.3}
      assert Enum.at(bids, 1) == %PricePoint{price: 147.52, size: 10.1}

      assert Enum.count(asks) == 2
      assert Enum.at(asks, 0) == %PricePoint{price: 150.00, size: 1.3}
      assert Enum.at(asks, 1) == %PricePoint{price: 150.01, size: 1.1}
    end

    test "can set last_received_at", %{book_pid: book_pid} do
      last_received_at = Timex.now()

      :ok =
        OrderBook.update(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          last_received_at: last_received_at,
          bids: %{},
          asks: %{}
        })

      assert {:ok, updated_book} = OrderBook.quotes(book_pid)
      assert updated_book.last_received_at == last_received_at
    end

    test "can set last_venue_timestamp", %{book_pid: book_pid} do
      last_venue_timestamp = Timex.now()

      :ok =
        OrderBook.update(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          last_venue_timestamp: last_venue_timestamp,
          bids: %{},
          asks: %{}
        })

      assert {:ok, updated_book} = OrderBook.quotes(book_pid)
      assert updated_book.last_venue_timestamp == last_venue_timestamp
    end

    test "removes prices when they have a size of 0", %{book_pid: book_pid} do
      :ok =
        OrderBook.replace(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{
            100.0 => 1.0,
            101.0 => 1.0
          },
          asks: %{
            102.0 => 1.0,
            103.0 => 1.0
          }
        })

      {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)

      assert bids == [
               %PricePoint{price: 101.0, size: 1.0},
               %PricePoint{price: 100.0, size: 1.0}
             ]

      assert asks == [
               %PricePoint{price: 102, size: 1.0},
               %PricePoint{price: 103, size: 1.0}
             ]

      :ok =
        OrderBook.update(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{100.0 => 0.0},
          asks: %{102.0 => 0}
        })

      assert {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)
      assert bids == [%PricePoint{price: 101.0, size: 1.0}]
      assert asks == [%PricePoint{price: 103.0, size: 1.0}]
    end

    test "broadcasts a pubsub event" do
      venue = @venue
      start_supervised!(Subscriber)
      Subscriber.subscribe_to_order_book_changes()

      bid_processed_at = Timex.now()
      bid_server_changed_at = Timex.now()
      ask_processed_at = Timex.now()
      ask_server_changed_at = Timex.now()

      :ok =
        OrderBook.update(%OrderBook{
          venue_id: venue,
          product_symbol: :btc_usd,
          bids: %{100.0 => {0.1, bid_processed_at, bid_server_changed_at}},
          asks: %{102.0 => {0.2, ask_processed_at, ask_server_changed_at}}
        })

      assert_receive {
        :order_book_changes,
        ^venue,
        :btc_usd,
        %OrderBook{
          bids: %{100.0 => {0.1, bp, bs}},
          asks: %{102.0 => {0.2, ap, as}}
        }
      }

      assert DateTime.compare(bp, bid_processed_at)
      assert DateTime.compare(bs, bid_server_changed_at)
      assert DateTime.compare(ap, ask_processed_at)
      assert DateTime.compare(as, ask_server_changed_at)
    end
  end

  describe ".quotes" do
    test "returns a price ordered list of all bids and asks", %{book_pid: book_pid} do
      :ok =
        OrderBook.replace(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{
            146.00 => 10.1,
            147.51 => 10.2
          },
          asks: %{
            150.02 => 1.2,
            150.00 => 1.3
          }
        })

      {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(book_pid)

      assert Enum.count(bids) == 2
      assert Enum.at(bids, 0) == %PricePoint{price: 147.51, size: 10.2}
      assert Enum.at(bids, 1) == %PricePoint{price: 146.00, size: 10.1}

      assert Enum.count(asks) == 2
      assert Enum.at(asks, 0) == %PricePoint{price: 150.00, size: 1.3}
      assert Enum.at(asks, 1) == %PricePoint{price: 150.02, size: 1.2}
    end

    test "can limit the depth of bids and asks returned", %{book_pid: book_pid} do
      :ok =
        OrderBook.replace(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{
            146.00 => 10.1,
            147.51 => 10.2,
            147 => 10.3
          },
          asks: %{
            151 => 1.1,
            150.02 => 1.2,
            150.00 => 1.3
          }
        })

      assert {:ok, %{bids: bids, asks: asks}} = OrderBook.quotes(book_pid, 2)

      assert Enum.count(bids) == 2
      assert Enum.at(bids, 0) == %PricePoint{price: 147.51, size: 10.2}
      assert Enum.at(bids, 1) == %PricePoint{price: 147, size: 10.3}

      assert Enum.count(asks) == 2
      assert Enum.at(asks, 0) == %PricePoint{price: 150.00, size: 1.3}
      assert Enum.at(asks, 1) == %PricePoint{price: 150.02, size: 1.2}
    end
  end

  describe ".inside_quote" do
    test "returns the largest bid & lowest ask with update timestamps" do
      last_received_at = Timex.now()
      last_venue_timestamp = Timex.now()

      :ok =
        OrderBook.replace(%OrderBook{
          venue_id: @venue,
          product_symbol: :btc_usd,
          bids: %{
            146.00 => {10.1, nil, nil},
            147.51 => {10.2, nil, nil}
          },
          asks: %{
            151 => {1.1, nil, nil},
            150.00 => {1.3, nil, nil}
          },
          last_received_at: last_received_at,
          last_venue_timestamp: last_venue_timestamp
        })

      assert {:ok, inside_quote} = OrderBook.inside_quote(@venue, :btc_usd)
      assert %Quote{} = inside_quote
      assert inside_quote.bid.price == 147.51
      assert inside_quote.ask.price == 150
      assert inside_quote.last_received_at == last_received_at
      assert inside_quote.last_venue_timestamp == last_venue_timestamp
    end
  end
end
