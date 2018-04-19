defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case, async: true
  doctest Tai.Markets.OrderBook

  alias Tai.Markets.{OrderBook, PriceLevel}

  defmodule Subscriber do
    use GenServer

    def start_link(_), do: GenServer.start_link(__MODULE__, :ok)
    def init(state), do: {:ok, state}

    def subscribe_to_order_book_snapshot do
      Tai.PubSub.subscribe({:order_book_snapshot, :my_test_feed, :btcusd})
    end

    def subscribe_to_order_book_changes do
      Tai.PubSub.subscribe({:order_book_changes, :my_test_feed, :btcusd})
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
    book_pid = start_supervised!({OrderBook, feed_id: :my_test_feed, symbol: :btcusd})

    %{book_pid: book_pid}
  end

  test "replace overrides the bids & asks", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
        bids: %{
          999.9 => {1.1, nil, nil},
          999.8 => {1.0, nil, nil}
        },
        asks: %{
          1000.0 => {0.1, nil, nil},
          1000.1 => {0.11, nil, nil}
        }
      })

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes()

    assert bids == [
             %PriceLevel{price: 999.9, size: 1.1, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 999.8, size: 1.0, processed_at: nil, server_changed_at: nil}
           ]

    assert asks == [
             %PriceLevel{price: 1000.0, size: 0.1, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 1000.1, size: 0.11, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "replace broadcasts a pubsub event", %{book_pid: book_pid} do
    start_supervised!(Subscriber)
    Subscriber.subscribe_to_order_book_snapshot()

    bid_processed_at = Timex.now()
    bid_server_changed_at = Timex.now()
    ask_processed_at = Timex.now()
    ask_server_changed_at = Timex.now()

    :ok =
      OrderBook.replace(book_pid, %OrderBook{
        bids: %{999.9 => {1.1, bid_processed_at, bid_server_changed_at}},
        asks: %{1000.0 => {0.1, ask_processed_at, ask_server_changed_at}}
      })

    assert_receive {
      :order_book_snapshot,
      :my_test_feed,
      :btcusd,
      %OrderBook{
        bids: %{999.9 => {1.1, bp, bs}},
        asks: %{1000.0 => {0.1, ap, as}}
      }
    }

    assert DateTime.compare(bp, bid_processed_at)
    assert DateTime.compare(bs, bid_server_changed_at)
    assert DateTime.compare(ap, ask_processed_at)
    assert DateTime.compare(as, ask_server_changed_at)
  end

  test "update replaces the given bids and asks", %{book_pid: book_pid} do
    :ok =
      OrderBook.update(book_pid, %OrderBook{
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

    {:ok, %OrderBook{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes()

    assert bids == [
             %PriceLevel{price: 147.53, size: 10.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 147.52, size: 10.1, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 147.51, size: 10.2, processed_at: nil, server_changed_at: nil}
           ]

    assert asks == [
             %PriceLevel{price: 150.00, size: 1.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 150.01, size: 1.1, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 150.02, size: 1.2, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "update removes prices when they have a size of 0", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
        bids: %{
          100.0 => {1.0, nil, nil},
          101.0 => {1.0, nil, nil}
        },
        asks: %{
          102.0 => {1.0, nil, nil},
          103.0 => {1.0, nil, nil}
        }
      })

    {:ok, %OrderBook{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes()

    assert bids == [
             %PriceLevel{price: 101.0, size: 1.0, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 100.0, size: 1.0, processed_at: nil, server_changed_at: nil}
           ]

    assert asks == [
             %PriceLevel{price: 102, size: 1.0, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 103, size: 1.0, processed_at: nil, server_changed_at: nil}
           ]

    :ok =
      OrderBook.update(book_pid, %OrderBook{
        bids: %{100.0 => {0.0, nil, nil}},
        asks: %{102.0 => {0, nil, nil}}
      })

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes()

    assert bids == [
             %PriceLevel{price: 101.0, size: 1.0, processed_at: nil, server_changed_at: nil}
           ]

    assert asks == [
             %PriceLevel{price: 103.0, size: 1.0, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "update broadcasts a pubsub event", %{book_pid: book_pid} do
    start_supervised!(Subscriber)
    Subscriber.subscribe_to_order_book_changes()

    bid_processed_at = Timex.now()
    bid_server_changed_at = Timex.now()
    ask_processed_at = Timex.now()
    ask_server_changed_at = Timex.now()

    :ok =
      OrderBook.update(book_pid, %OrderBook{
        bids: %{100.0 => {0.1, bid_processed_at, bid_server_changed_at}},
        asks: %{102.0 => {0.2, ask_processed_at, ask_server_changed_at}}
      })

    assert_receive {
      :order_book_changes,
      :my_test_feed,
      :btcusd,
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

  test "quotes returns a price ordered list of all bids and asks", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes()

    assert bids == [
             %PriceLevel{price: 147.51, size: 10.2, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 147, size: 10.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 146.00, size: 10.1, processed_at: nil, server_changed_at: nil}
           ]

    assert asks == [
             %PriceLevel{price: 150.00, size: 1.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 150.02, size: 1.2, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 151, size: 1.1, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "quotes can limit the depth of bids and asks returned", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes(2)

    assert bids == [
             %PriceLevel{price: 147.51, size: 10.2, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 147, size: 10.3, processed_at: nil, server_changed_at: nil}
           ]

    assert asks == [
             %PriceLevel{price: 150.00, size: 1.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 150.02, size: 1.2, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "bids returns a full price ordered list", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, bids} = book_pid |> OrderBook.bids()

    assert bids == [
             %PriceLevel{price: 147.51, size: 10.2, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 147, size: 10.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 146.00, size: 10.1, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "bids can limit the depth returned", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, bids} = book_pid |> OrderBook.bids(2)

    assert bids == [
             %PriceLevel{price: 147.51, size: 10.2, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 147, size: 10.3, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "bid returns the first item", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, bid} = book_pid |> OrderBook.bid()

    assert bid == %PriceLevel{
             price: 147.51,
             size: 10.2,
             processed_at: nil,
             server_changed_at: nil
           }
  end

  test "asks returns a full price ordered list", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, asks} = book_pid |> OrderBook.asks()

    assert asks == [
             %PriceLevel{price: 150.00, size: 1.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 150.02, size: 1.2, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 151, size: 1.1, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "asks can limit the depth returned", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, asks} = book_pid |> OrderBook.asks(2)

    assert asks == [
             %PriceLevel{price: 150.00, size: 1.3, processed_at: nil, server_changed_at: nil},
             %PriceLevel{price: 150.02, size: 1.2, processed_at: nil, server_changed_at: nil}
           ]
  end

  test "ask returns the first item", %{book_pid: book_pid} do
    :ok =
      OrderBook.replace(book_pid, %OrderBook{
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

    {:ok, ask} = book_pid |> OrderBook.ask()

    assert ask == %PriceLevel{price: 150.00, size: 1.3, processed_at: nil, server_changed_at: nil}
  end
end
