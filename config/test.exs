use Mix.Config

config :exvcr,
  filter_request_headers: [
    # GDAX
    "CB-ACCESS-KEY",
    "CB-ACCESS-SIGN",
    "CB-ACCESS-TIMESTAMP",
    "CB-ACCESS-PASSPHRASE",
    # Poloniex
    "Key",
    "Sign",
    # Binance
    "X-MBX-APIKEY"
  ],
  filter_sensitive_data: [
    # GDAX
    [pattern: "\"id\":\"[a-z0-9-]{36,36}\"", placeholder: "\"id\":\"***\""],
    [pattern: "\"profile_id\":\"[a-z0-9-]{36,36}\"", placeholder: "\"profile_id\":\"***\""],
    # Binance
    [pattern: "signature=[A-Z0-9]+", placeholder: "signature=***"]
  ]

config(:echo_boy, port: 4100)

config :ex_gdax,
  api_key: System.get_env("GDAX_API_KEY"),
  api_secret: System.get_env("GDAX_API_SECRET"),
  api_passphrase: System.get_env("GDAX_API_PASSPHRASE")

config :ex_poloniex,
  api_key: System.get_env("POLONIEX_API_KEY"),
  api_secret: System.get_env("POLONIEX_API_SECRET")

config :binance,
  api_key: System.get_env("BINANCE_API_KEY"),
  secret_key: System.get_env("BINANCE_API_SECRET")

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
      adapter: Tai.ExchangeAdapters.Test.Account
    ],
    test_account_b: [
      adapter: Tai.ExchangeAdapters.Test.Account
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
      id: :fill_or_kill_orders,
      supervisor: Examples.Advisors.FillOrKillOrders.Supervisor,
      order_books: "test_feed_a test_feed_b.ethusd"
    },
    %{
      id: :log_spread_advisor,
      supervisor: Examples.Advisors.LogSpread.Supervisor,
      order_books: "*"
    }
  ]
