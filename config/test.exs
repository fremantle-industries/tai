use Mix.Config

config :examples, :e2e_mappings, %{
  log_spread: ExamplesSupport.E2E.LogSpread,
  fill_or_kill_orders: ExamplesSupport.E2E.FillOrKillOrders,
  create_and_cancel_pending_order: ExamplesSupport.E2E.CreateAndCancelPendingOrder,
  ping_pong: ExamplesSupport.E2E.PingPong
}

config :tai,
  send_orders: true,
  venue_boot_handler: Tai.TestSupport.VenueBootHandler,
  e2e_app: :examples

config :tai, advisor_groups: %{}

config(:tai,
  test_venue_adapters: %{
    mock: [
      enabled: true,
      adapter: Tai.VenueAdapters.Mock,
      accounts: %{main: %{}},
      opts: %{}
    ],
    bitmex: [
      enabled: true,
      adapter: Tai.VenueAdapters.Bitmex,
      accounts: %{
        main: %{
          api_key: {:system_file, "BITMEX_API_KEY"},
          api_secret: {:system_file, "BITMEX_API_SECRET"}
        }
      },
      opts: %{
        autocancel: %{ping_interval_ms: 15_000, cancel_after_ms: 60_000}
      }
    ],
    okex: [
      enabled: true,
      adapter: Tai.VenueAdapters.OkEx,
      accounts: %{
        main: %{
          api_key: {:system_file, "OKEX_API_KEY"},
          api_secret: {:system_file, "OKEX_API_SECRET"},
          api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
        }
      },
      opts: %{}
    ],
    okex_futures: [
      enabled: true,
      adapter: Tai.VenueAdapters.OkEx,
      accounts: %{
        main: %{
          api_key: {:system_file, "OKEX_API_KEY"},
          api_secret: {:system_file, "OKEX_API_SECRET"},
          api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
        }
      },
      opts: %{}
    ],
    okex_swap: [
      enabled: true,
      adapter: Tai.VenueAdapters.OkEx,
      accounts: %{
        main: %{
          api_key: {:system_file, "OKEX_API_KEY"},
          api_secret: {:system_file, "OKEX_API_SECRET"},
          api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
        }
      },
      opts: %{}
    ],
    okex_spot: [
      enabled: true,
      adapter: Tai.VenueAdapters.OkEx,
      accounts: %{
        main: %{
          api_key: {:system_file, "OKEX_API_KEY"},
          api_secret: {:system_file, "OKEX_API_SECRET"},
          api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
        }
      },
      opts: %{}
    ],
    binance: [
      enabled: true,
      adapter: Tai.VenueAdapters.Binance,
      accounts: %{
        main: %{
          api_key: {:system_file, "BINANCE_API_KEY"},
          secret_key: {:system_file, "BINANCE_API_SECRET"}
        }
      }
    ],
    poloniex: [
      enabled: true,
      adapter: Tai.VenueAdapters.Poloniex,
      accounts: %{main: %{}}
    ],
    gdax: [
      enabled: true,
      adapter: Tai.VenueAdapters.Gdax,
      accounts: %{
        main: %{
          api_url: "https://api-public.sandbox.pro.coinbase.com",
          api_key: {:system_file, "GDAX_API_KEY"},
          api_secret: {:system_file, "GDAX_API_SECRET"},
          api_passphrase: {:system_file, "GDAX_API_PASSPHRASE"}
        }
      }
    ]
  }
)

config(:tai, :test_venue_adapters_products, [:mock, :binance, :poloniex, :gdax, :okex])
config(:tai, :test_venue_adapters_asset_balances, [:mock, :binance, :poloniex, :gdax, :okex])
config(:tai, :test_venue_adapters_maker_taker_fees, [:mock, :binance, :poloniex, :gdax, :okex])
config(:tai, :test_venue_adapters_create_order_gtc_open, [:bitmex, :binance])
config(:tai, :test_venue_adapters_create_order_gtc_accepted, [:okex_futures, :okex_swap])
config(:tai, :test_venue_adapters_create_order_fok, [:bitmex, :binance])
config(:tai, :test_venue_adapters_create_order_ioc, [:bitmex, :binance])
config(:tai, :test_venue_adapters_create_order_close, [:okex_futures, :okex_swap])

config(:tai, :test_venue_adapters_create_order_error_insufficient_balance, [
  :bitmex,
  :okex_futures,
  :okex_swap,
  :binance
])

config(:tai, :test_venue_adapters_create_order_error, [:bitmex])
config(:tai, :test_venue_adapters_cancel_order, [:bitmex, :binance])
config(:tai, :test_venue_adapters_cancel_order_accepted, [:okex_futures, :okex_swap])

config(:tai, :test_venue_adapters_cancel_order_error_not_found, [
  :binance,
  :okex_futures,
  :okex_swap
])

config(:tai, :test_venue_adapters_cancel_order_error_timeout, [:bitmex, :okex_futures, :okex_swap])

config(:tai, :test_venue_adapters_cancel_order_error_overloaded, [:bitmex])
config(:tai, :test_venue_adapters_cancel_order_error_nonce_not_increasing, [:bitmex])
config(:tai, :test_venue_adapters_cancel_order_error_rate_limited, [:bitmex])
config(:tai, :test_venue_adapters_cancel_order_error_unhandled, [:bitmex, :binance])
config(:tai, :test_venue_adapters_with_positions, [:bitmex])

config :tai,
  venues: %{
    test_exchange_a: [
      enabled: true,
      adapter: Tai.VenueAdapters.Mock,
      products: "btc_usd ltc_usd",
      accounts: %{main: %{}}
    ],
    test_exchange_b: [
      enabled: true,
      adapter: Tai.VenueAdapters.Mock,
      products: "eth_usd ltc_usd",
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
    "X-MBX-APIKEY",
    # Bitmex
    "api-key",
    "api-nonce",
    "api-signature",
    # OkEx
    "OK-ACCESS-KEY",
    "OK-ACCESS-SIGN",
    "OK-ACCESS-TIMESTAMP",
    "OK-ACCESS-PASSPHRASE"
  ],
  filter_sensitive_data: [
    # GDAX
    [pattern: "\"id\":\"[a-z0-9-]{36,36}\"", placeholder: "\"id\":\"***\""],
    [pattern: "\"profile_id\":\"[a-z0-9-]{36,36}\"", placeholder: "\"profile_id\":\"***\""],
    # Binance
    [pattern: "signature=[A-Z0-9]+", placeholder: "signature=***"]
  ]

config :echo_boy, port: 4100

config :ex_bitmex, domain: "testnet.bitmex.com"

config :ex_poloniex,
  api_key: {:system_file, "POLONIEX_API_KEY"},
  api_secret: {:system_file, "POLONIEX_API_SECRET"}
