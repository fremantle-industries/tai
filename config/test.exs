use Mix.Config

config :tai, send_orders: true
config :tai, exchange_boot_handler: Tai.TestSupport.ExchangeBootHandler

config :tai,
  advisor_groups: %{
    log_spread: [
      advisor: Examples.Advisors.LogSpread.Advisor,
      factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
      products: "*"
    ],
    fill_or_kill_orders: [
      advisor: Examples.Advisors.FillOrKillOrders.Advisor,
      factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
      products: "test_exchange_a test_exchange_b.eth_usd"
    ],
    create_and_cancel_pending_order: [
      advisor: Examples.Advisors.CreateAndCancelPendingOrder.Advisor,
      factory: Tai.Advisors.Factories.OnePerVenueAndProduct,
      products: "test_feed_a test_feed_b.eth_usd"
    ]
  }

config(:tai,
  test_venue_adapters: %{
    mock: [
      adapter: Tai.VenueAdapters.Mock,
      accounts: %{main: %{}}
    ],
    bitmex: [
      adapter: Tai.VenueAdapters.Bitmex,
      accounts: %{
        main: %{
          api_key: System.get_env("BITMEX_API_KEY"),
          api_secret: System.get_env("BITMEX_SECRET")
        }
      }
    ],
    binance: [
      adapter: Tai.VenueAdapters.Binance,
      accounts: %{main: %{}}
    ],
    poloniex: [
      adapter: Tai.VenueAdapters.Poloniex,
      accounts: %{main: %{}}
    ],
    gdax: [
      adapter: Tai.VenueAdapters.Gdax,
      accounts: %{
        main: %{
          api_url: "https://api-public.sandbox.pro.coinbase.com",
          api_key: System.get_env("GDAX_API_KEY"),
          api_secret: System.get_env("GDAX_API_SECRET"),
          api_passphrase: System.get_env("GDAX_API_PASSPHRASE")
        }
      }
    ]
  }
)

config :tai,
  venues: %{
    test_exchange_a: [
      adapter: Tai.VenueAdapters.Mock,
      products: "btc_usd ltc_usd",
      accounts: %{main: %{}}
    ],
    test_exchange_b: [
      adapter: Tai.VenueAdapters.Mock,
      products: "eth_usd ltc_usd",
      accounts: %{main: %{}}
    ]
  }

config :tai,
  exchanges: %{
    test_exchange_a: [
      supervisor: Tai.ExchangeAdapters.Mock.Supervisor,
      accounts: %{main: %{}}
    ],
    test_exchange_b: [
      supervisor: Tai.ExchangeAdapters.Mock.Supervisor,
      accounts: %{main: %{}}
    ]
  }

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

config :logger, backends: [{LoggerFileBackend, :file_log}]

config(:echo_boy, port: 4100)

config :ex_bitmex, domain: "testnet.bitmex.com"

config :ex_poloniex,
  api_key: System.get_env("POLONIEX_API_KEY"),
  api_secret: System.get_env("POLONIEX_API_SECRET")

config :binance,
  api_key: System.get_env("BINANCE_API_KEY"),
  secret_key: System.get_env("BINANCE_API_SECRET")
