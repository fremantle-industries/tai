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
  accounts: %{
    test_account_a: [
      supervisor: Tai.ExchangeAdapters.Test.AccountSupervisor
    ],
    test_account_b: [
      supervisor: Tai.ExchangeAdapters.Test.AccountSupervisor
    ]
  }

config :tai,
  advisors: [
    %{
      id: :create_and_cancel_pending_order,
      supervisor: Examples.Advisors.CreateAndCancelPendingOrder.Supervisor,
      order_books: "test_feed_a test_feed_b.ethusd"
    },
    %{
      id: :log_spread_advisor,
      supervisor: Examples.Advisors.LogSpread.Supervisor,
      order_books: "*"
    }
  ]
