defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case, async: true
  doctest Tai.Markets.OrderBook

  alias Tai.Markets

  defmodule Subscriber do
    use GenServer

    def start_link(_), do: GenServer.start_link(__MODULE__, :ok)
    def init(state), do: {:ok, state}

    def subscribe_to_order_book_snapshot do
      Tai.PubSub.subscribe({:order_book_snapshot, :my_test_feed, :btc_usd})
    end

    def subscribe_to_order_book_changes do
      Tai.PubSub.subscribe({:order_book_changes, :my_test_feed, :btc_usd})
    end

    def handle_info({:order_book_snapshot, _feed_id, _symbol, _snapshot} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end

    def handle_info({:order_book_changes, _feed_id, _symbol, _changes} = msg, state) do
      send(:test, msg)
      {:noreply, state}
    end
  end

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    book_pid = start_supervised!({Markets.OrderBook, feed_id: :my_test_feed, symbol: :btc_usd})

    %{book_pid: book_pid}
  end

  describe ".replace" do
    test "overrides the bids & asks", %{book_pid: book_pid} do
      :ok =
        Markets.OrderBook.replace(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{
            999.9 => {1.1, nil, nil},
            999.8 => {1.0, nil, nil}
          },
          asks: %{
            1000.0 => {0.1, nil, nil},
            1000.1 => {0.11, nil, nil}
          }
        })

      {:ok, %{bids: bids, asks: asks}} = book_pid |> Markets.OrderBook.quotes()

      assert bids == [
               %Markets.PriceLevel{
                 price: 999.9,
                 size: 1.1,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 999.8,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      assert asks == [
               %Markets.PriceLevel{
                 price: 1000.0,
                 size: 0.1,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 1000.1,
                 size: 0.11,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]
    end

    test "broadcasts a pubsub event", %{book_pid: book_pid} do
      start_supervised!(Subscriber)
      Subscriber.subscribe_to_order_book_snapshot()

      bid_processed_at = Timex.now()
      bid_server_changed_at = Timex.now()
      ask_processed_at = Timex.now()
      ask_server_changed_at = Timex.now()

      :ok =
        Markets.OrderBook.replace(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{999.9 => {1.1, bid_processed_at, bid_server_changed_at}},
          asks: %{1000.0 => {0.1, ask_processed_at, ask_server_changed_at}}
        })

      assert_receive {
        :order_book_snapshot,
        :my_test_feed,
        :btc_usd,
        %Markets.OrderBook{
          bids: %{999.9 => {1.1, bp, bs}},
          asks: %{1000.0 => {0.1, ap, as}}
        }
      }

      assert DateTime.compare(bp, bid_processed_at)
      assert DateTime.compare(bs, bid_server_changed_at)
      assert DateTime.compare(ap, ask_processed_at)
      assert DateTime.compare(as, ask_server_changed_at)
    end

    test "broadcasts a system event", %{book_pid: book_pid} do
      Tai.Events.firehose_subscribe()

      snapshot = %Markets.OrderBook{
        venue_id: :my_test_feed,
        product_symbol: :btc_usd,
        bids: %{999.9 => {0.1, Timex.now(), Timex.now()}},
        asks: %{1000.0 => {0.1, Timex.now(), Timex.now()}}
      }

      assert Markets.OrderBook.replace(book_pid, snapshot) == :ok

      assert_receive {Tai.Event,
                      %Tai.Events.OrderBookSnapshot{
                        venue_id: :my_test_feed,
                        symbol: :btc_usd,
                        snapshot: ^snapshot
                      }}
    end
  end

  describe ".update" do
    test "changes the given bids and asks", %{book_pid: book_pid} do
      :ok =
        Markets.OrderBook.update(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{
            147.52 => {10.1, nil, nil},
            147.51 => {10.2, nil, nil},
            147.53 => {10.3, nil, nil}
          },
          asks: %{
            150.01 => {1.1, nil, nil},
            150.02 => {1.2, nil, nil},
            150.00 => {1.3, nil, nil}
          }
        })

      {:ok, %Markets.OrderBook{bids: bids, asks: asks}} = book_pid |> Markets.OrderBook.quotes()

      assert bids == [
               %Markets.PriceLevel{
                 price: 147.53,
                 size: 10.3,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 147.52,
                 size: 10.1,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 147.51,
                 size: 10.2,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      assert asks == [
               %Markets.PriceLevel{
                 price: 150.00,
                 size: 1.3,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 150.01,
                 size: 1.1,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 150.02,
                 size: 1.2,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]
    end

    test "removes prices when they have a size of 0", %{book_pid: book_pid} do
      :ok =
        Markets.OrderBook.replace(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{
            100.0 => {1.0, nil, nil},
            101.0 => {1.0, nil, nil}
          },
          asks: %{
            102.0 => {1.0, nil, nil},
            103.0 => {1.0, nil, nil}
          }
        })

      {:ok, %Markets.OrderBook{bids: bids, asks: asks}} = book_pid |> Markets.OrderBook.quotes()

      assert bids == [
               %Markets.PriceLevel{
                 price: 101.0,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 100.0,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      assert asks == [
               %Markets.PriceLevel{
                 price: 102,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 103,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      :ok =
        Markets.OrderBook.update(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{100.0 => {0.0, nil, nil}},
          asks: %{102.0 => {0, nil, nil}}
        })

      {:ok, %{bids: bids, asks: asks}} = book_pid |> Markets.OrderBook.quotes()

      assert bids == [
               %Markets.PriceLevel{
                 price: 101.0,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      assert asks == [
               %Markets.PriceLevel{
                 price: 103.0,
                 size: 1.0,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]
    end

    test "broadcasts a pubsub event", %{book_pid: book_pid} do
      start_supervised!(Subscriber)
      Subscriber.subscribe_to_order_book_changes()

      bid_processed_at = Timex.now()
      bid_server_changed_at = Timex.now()
      ask_processed_at = Timex.now()
      ask_server_changed_at = Timex.now()

      :ok =
        Markets.OrderBook.update(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{100.0 => {0.1, bid_processed_at, bid_server_changed_at}},
          asks: %{102.0 => {0.2, ask_processed_at, ask_server_changed_at}}
        })

      assert_receive {
        :order_book_changes,
        :my_test_feed,
        :btc_usd,
        %Markets.OrderBook{
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
        Markets.OrderBook.replace(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{
            146.00 => {10.1, nil, nil},
            147.51 => {10.2, nil, nil},
            147 => {10.3, nil, nil}
          },
          asks: %{
            151 => {1.1, nil, nil},
            150.02 => {1.2, nil, nil},
            150.00 => {1.3, nil, nil}
          }
        })

      {:ok, %{bids: bids, asks: asks}} = book_pid |> Markets.OrderBook.quotes()

      assert bids == [
               %Markets.PriceLevel{
                 price: 147.51,
                 size: 10.2,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 147,
                 size: 10.3,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 146.00,
                 size: 10.1,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      assert asks == [
               %Markets.PriceLevel{
                 price: 150.00,
                 size: 1.3,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 150.02,
                 size: 1.2,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 151,
                 size: 1.1,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]
    end

    test "can limit the depth of bids and asks returned", %{book_pid: book_pid} do
      :ok =
        Markets.OrderBook.replace(book_pid, %Markets.OrderBook{
          venue_id: :my_test_feed,
          product_symbol: :btc_usd,
          bids: %{
            146.00 => {10.1, nil, nil},
            147.51 => {10.2, nil, nil},
            147 => {10.3, nil, nil}
          },
          asks: %{
            151 => {1.1, nil, nil},
            150.02 => {1.2, nil, nil},
            150.00 => {1.3, nil, nil}
          }
        })

      {:ok, %{bids: bids, asks: asks}} = book_pid |> Markets.OrderBook.quotes(2)

      assert bids == [
               %Markets.PriceLevel{
                 price: 147.51,
                 size: 10.2,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 147,
                 size: 10.3,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]

      assert asks == [
               %Markets.PriceLevel{
                 price: 150.00,
                 size: 1.3,
                 processed_at: nil,
                 server_changed_at: nil
               },
               %Markets.PriceLevel{
                 price: 150.02,
                 size: 1.2,
                 processed_at: nil,
                 server_changed_at: nil
               }
             ]
    end
  end
end
