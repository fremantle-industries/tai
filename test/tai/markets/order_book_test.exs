defmodule Tai.Markets.OrderBookTest do
  use ExUnit.Case, async: true
  doctest Tai.Markets.OrderBook

  alias Tai.Markets.OrderBook

  setup do
    book_pid = start_supervised!({OrderBook, feed_id: :my_test_feed, symbol: :btcusd})

    %{book_pid: book_pid}
  end

  test "replace overrides the bids & asks", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
        bids: %{
          999.9 => {1.1, nil, nil},
          999.8 => {1.0, nil, nil}
        },
        asks: %{
          1000.0 => {0.1, nil, nil},
          1000.1 => {0.11, nil, nil}
        }
      }
    )

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes
    assert bids == [
      [price: 999.9, size: 1.1, processed_at: nil, updated_at: nil],
      [price: 999.8, size: 1.0, processed_at: nil, updated_at: nil]
    ]
    assert asks == [
      [price: 1000.0, size: 0.1, processed_at: nil, updated_at: nil],
      [price: 1000.1, size: 0.11, processed_at: nil, updated_at: nil]
    ]
  end

  test "update replaces the given bids and asks", %{book_pid: book_pid} do
    :ok = OrderBook.update(
      book_pid,
      %{
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
      }
    )

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes
    assert bids == [
      [price: 147.53, size: 10.3, processed_at: nil, updated_at: nil],
      [price: 147.52, size: 10.1, processed_at: nil, updated_at: nil],
      [price: 147.51, size: 10.2, processed_at: nil, updated_at: nil]
    ]
    assert asks == [
      [price: 150.00, size: 1.3, processed_at: nil, updated_at: nil],
      [price: 150.01, size: 1.1, processed_at: nil, updated_at: nil],
      [price: 150.02, size: 1.2, processed_at: nil, updated_at: nil]
    ]
  end

  test "update removes prices when they have a size of 0", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
        bids: %{
          100.0 => {1.0, nil, nil},
          101.0 => {1.0, nil, nil}
        },
        asks: %{
          102.0 => {1.0, nil, nil},
          103.0 => {1.0, nil, nil}
        }
      }
    )

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes
    assert bids == [
      [price: 101.0, size: 1.0, processed_at: nil, updated_at: nil],
      [price: 100.0, size: 1.0, processed_at: nil, updated_at: nil]
    ]
    assert asks == [
      [price: 102, size: 1.0, processed_at: nil, updated_at: nil],
      [price: 103, size: 1.0, processed_at: nil, updated_at: nil]
    ]

    :ok = OrderBook.update(
      book_pid,
      %{
        bids: %{100.0 => {0.0, nil, nil}},
        asks: %{102.0 => {0, nil, nil}}
      }
    )

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes
    assert bids == [[price: 101.0, size: 1.0, processed_at: nil, updated_at: nil]]
    assert asks == [[price: 103.0, size: 1.0, processed_at: nil, updated_at: nil]]
  end

  test "quotes returns a price ordered list of all bids and asks", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes

    assert bids == [
      [price: 147.51, size: 10.2, processed_at: nil, updated_at: nil],
      [price: 147, size: 10.3, processed_at: nil, updated_at: nil],
      [price: 146.00, size: 10.1, processed_at: nil, updated_at: nil]
    ]
    assert asks == [
      [price: 150.00, size: 1.3, processed_at: nil, updated_at: nil],
      [price: 150.02, size: 1.2, processed_at: nil, updated_at: nil],
      [price: 151, size: 1.1, processed_at: nil, updated_at: nil]
    ]
  end

  test "quotes can limit the depth of bids and asks returned", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, %{bids: bids, asks: asks}} = book_pid |> OrderBook.quotes(2)

    assert bids == [
      [price: 147.51, size: 10.2, processed_at: nil, updated_at: nil],
      [price: 147, size: 10.3, processed_at: nil, updated_at: nil]
    ]
    assert asks == [
      [price: 150.00, size: 1.3, processed_at: nil, updated_at: nil],
      [price: 150.02, size: 1.2, processed_at: nil, updated_at: nil]
    ]
  end

  test "bids returns a full price ordered list", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, bids} = book_pid |> OrderBook.bids

    assert bids == [
      [price: 147.51, size: 10.2, processed_at: nil, updated_at: nil],
      [price: 147, size: 10.3, processed_at: nil, updated_at: nil],
      [price: 146.00, size: 10.1, processed_at: nil, updated_at: nil]
    ]
  end

  test "bids can limit the depth returned", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, bids} = book_pid |> OrderBook.bids(2)

    assert bids == [
      [price: 147.51, size: 10.2, processed_at: nil, updated_at: nil],
      [price: 147, size: 10.3, processed_at: nil, updated_at: nil]
    ]
  end

  test "bid returns the first item", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, bid} = book_pid |> OrderBook.bid()

    assert bid == [price: 147.51, size: 10.2, processed_at: nil, updated_at: nil]
  end

  test "asks returns a full price ordered list", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, asks} = book_pid |> OrderBook.asks

    assert asks == [
      [price: 150.00, size: 1.3, processed_at: nil, updated_at: nil],
      [price: 150.02, size: 1.2, processed_at: nil, updated_at: nil],
      [price: 151, size: 1.1, processed_at: nil, updated_at: nil]
    ]
  end

  test "asks can limit the depth returned", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, asks} = book_pid |> OrderBook.asks(2)

    assert asks == [
      [price: 150.00, size: 1.3, processed_at: nil, updated_at: nil],
      [price: 150.02, size: 1.2, processed_at: nil, updated_at: nil]
    ]
  end

  test "ask returns the first item", %{book_pid: book_pid} do
    :ok = OrderBook.replace(
      book_pid,
      %{
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
      }
    )

    {:ok, ask} = book_pid |> OrderBook.ask()

    assert ask == [price: 150.00, size: 1.3, processed_at: nil, updated_at: nil]
  end
end
