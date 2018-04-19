use Mix.Config

config :echo_boy, port: 4100

config :ex_gdax,
  api_key: System.get_env("GDAX_API_KEY"),
  api_secret: System.get_env("GDAX_API_SECRET"),
  api_passphrase: System.get_env("GDAX_API_PASSPHRASE")

config :tai,
  order_book_feeds: %{
    test_feed_a: [
      adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
      order_books: [:btcusd, :ltcusd]
    ],
    test_feed_b: [
      adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
      order_books: [:ethusd, :ltcusd]
    ]
  }

config :tai,
  exchanges: %{
    test_exchange_a: [
      supervisor: Tai.ExchangeAdapters.Test.Supervisor
    ],
    test_exchange_b: [
      supervisor: Tai.ExchangeAdapters.Test.Supervisor
    ]
  }

config :tai,
  advisors: %{
    test_advisor_a: [
      server: Examples.Advisors.CreateAndCancelPendingOrder,
      order_books: %{
        test_feed_a: [:btcusd, :ltcusd],
        test_feed_b: [:ethusd, :ltcusd]
      },
      exchanges: [:test_exchange_a, :test_exchange_b]
    ],
    test_advisor_b: [
      server: Examples.Advisors.CreateAndCancelPendingOrder,
      order_books: %{
        test_feed_a: [:btcusd],
        test_feed_b: [:ethusd]
      }
    ]
  }
