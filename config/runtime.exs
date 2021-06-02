import Config

# OrderRepo
config :tai, Tai.NewOrders.OrderRepo, pool_size: 10

if System.get_env("ORDER_REPO_ADAPTER") == "postgres" do
  default_database_url = "postgres://postgres:postgres@localhost:5432/tai_?"
  configured_database_url = System.get_env("DATABASE_URL") || default_database_url
  database_url = String.replace(configured_database_url, "?", "dev")
  config :tai, Tai.NewOrders.OrderRepo, url: database_url
end

# Toolkit
config :tai, send_orders: false
config :tai, broadcast_change_set: true
config :tai, advisor_groups: %{}
config :tai, venues: %{}

# Logger
config :logger,
  backends: [{LoggerFileBackendWithFormatters, :file_log}],
  utc_log: true

config :logger, :file_log, path: "./log/#{Mix.env()}.log"

# Conditional configuration
if config_env() == :dev do
  config :tai, Tai.NewOrders.OrderRepo,
    show_sensitive_data_on_connection_error: true

  config :tai,
    advisor_groups: %{
      log_spread: [
        advisor: Examples.LogSpread.Advisor,
        factory: Tai.Advisors.Factories.OnePerProduct,
        products: "binance.btc_usdt ftx.btc_usd"
      ]
    }

  config :tai,
    venues: %{
      ftx: [
        start_on_boot: true,
        adapter: Tai.VenueAdapters.Ftx,
        products: "btc/usd btc-perp btc-0326"
      ],
      binance: [
        start_on_boot: true,
        adapter: Tai.VenueAdapters.Binance,
        products: "btc_usdt ltc_usdt eth_usdt"
      ]
    }
end

if config_env() == :test do
  config :examples, :e2e_mappings, %{
    log_spread: ExamplesSupport.E2E.LogSpread,
    fill_or_kill_orders: ExamplesSupport.E2E.FillOrKillOrders,
    create_and_cancel_pending_order: ExamplesSupport.E2E.CreateAndCancelPendingOrder,
    ping_pong: ExamplesSupport.E2E.PingPong
  }

  config :tai, Tai.NewOrders.OrderRepo,
    pool: Ecto.Adapters.SQL.Sandbox,
    show_sensitive_data_on_connection_error: true

  config :tai, send_orders: true
  config :tai, e2e_app: :examples

  config :tai,
    test_venue_adapters: %{
      mock: [
        enabled: true,
        adapter: Tai.VenueAdapters.Mock,
        credentials: %{main: %{}},
        opts: %{}
      ],
      bitmex: [
        enabled: true,
        adapter: Tai.VenueAdapters.Bitmex,
        credentials: %{
          main: %{
            api_key: {:system_file, "BITMEX_API_KEY"},
            api_secret: {:system_file, "BITMEX_API_SECRET"}
          },
          error: %{
            api_key: "invalid",
            api_secret: "invalid"
          }
        },
        opts: %{
          autocancel: %{ping_interval_ms: 15_000, cancel_after_ms: 60_000}
        }
      ],
      okex: [
        enabled: true,
        adapter: Tai.VenueAdapters.OkEx,
        credentials: %{
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
        credentials: %{
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
        credentials: %{
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
        credentials: %{
          main: %{
            api_key: {:system_file, "OKEX_API_KEY"},
            api_secret: {:system_file, "OKEX_API_SECRET"},
            api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
          }
        },
        opts: %{}
      ],
      huobi: [
        enabled: true,
        adapter: Tai.VenueAdapters.Huobi,
        opts: %{}
      ],
      huobi_futures: [
        enabled: true,
        adapter: Tai.VenueAdapters.Huobi,
        opts: %{}
      ],
      binance: [
        enabled: true,
        adapter: Tai.VenueAdapters.Binance,
        credentials: %{
          main: %{
            api_key: {:system_file, "BINANCE_API_KEY"},
            secret_key: {:system_file, "BINANCE_API_SECRET"}
          }
        }
      ],
      deribit: [
        enabled: true,
        adapter: Tai.VenueAdapters.Deribit,
        credentials: %{
          main: %{
            client_id: {:system_file, "DERIBIT_CLIENT_ID"},
            client_secret: {:system_file, "DERIBIT_CLIENT_SECRET"}
          }
        }
      ],
      gdax: [
        enabled: true,
        adapter: Tai.VenueAdapters.Gdax,
        credentials: %{
          main: %{
            api_url: "https://api-public.sandbox.pro.coinbase.com",
            api_key: {:system_file, "GDAX_API_KEY"},
            api_secret: {:system_file, "GDAX_API_SECRET"},
            api_passphrase: {:system_file, "GDAX_API_PASSPHRASE"}
          }
        }
      ],
      ftx: [
        enabled: true,
        adapter: Tai.VenueAdapters.Ftx,
        credentials: %{
          main: %{
            api_key: {:system_file, "FTX_API_KEY"},
            api_secret: {:system_file, "FTX_API_SECRET"}
          }
        }
      ]
    }

  config :tai, :test_venue_adapters_products, [
    :binance,
    :bitmex,
    :deribit,
    :gdax,
    :mock,
    :okex,
    :huobi,
    :ftx
  ]

  config :tai, :test_venue_adapters_funding_rates, [:mock, :ftx]

  config :tai, :test_venue_adapters_accounts, [
    :binance,
    :bitmex,
    :deribit,
    :gdax,
    :mock,
    :okex,
    :ftx
  ]

  config :tai, :test_venue_adapters_accounts_error, [:bitmex]
  config :tai, :test_venue_adapters_maker_taker_fees, [:mock, :binance, :gdax, :okex, :ftx]
  config :tai, :test_venue_adapters_create_order_gtc_open, [:bitmex, :binance]

  config :tai, :test_venue_adapters_create_order_gtc_accepted, [
    :okex_futures,
    :okex_spot,
    :okex_swap,
    :ftx
  ]

  config :tai, :test_venue_adapters_create_order_fok, [:bitmex, :binance]
  config :tai, :test_venue_adapters_create_order_ioc, [:bitmex, :binance]
  config :tai, :test_venue_adapters_create_order_ioc_accepted, [:ftx]
  config :tai, :test_venue_adapters_create_order_close, [:okex_futures, :okex_swap]

  config :tai, :test_venue_adapters_create_order_error_insufficient_balance, [
    :bitmex,
    :okex_futures,
    :okex_swap,
    :binance
  ]

  config :tai, :test_venue_adapters_create_order_error, [:bitmex]
  config :tai, :test_venue_adapters_amend_order, [:bitmex]
  config :tai, :test_venue_adapters_amend_bulk_order, [:bitmex]
  config :tai, :test_venue_adapters_cancel_order, [:bitmex, :binance]

  config :tai, :test_venue_adapters_cancel_order_accepted, [
    :okex_futures,
    :okex_swap,
    :okex_spot,
    :ftx
  ]

  config :tai, :test_venue_adapters_cancel_order_error_not_found, [
    :binance,
    :okex_futures,
    :okex_swap,
    :ftx
  ]

  config :tai, :test_venue_adapters_cancel_order_error_timeout, [:bitmex, :okex_futures, :okex_swap]

  config :tai, :test_venue_adapters_cancel_order_error_overloaded, [:bitmex]
  config :tai, :test_venue_adapters_cancel_order_error_nonce_not_increasing, [:bitmex]
  config :tai, :test_venue_adapters_cancel_order_error_rate_limited, [:bitmex]
  config :tai, :test_venue_adapters_cancel_order_error_unhandled, [:bitmex, :binance]
  config :tai, :test_venue_adapters_with_positions, [:bitmex, :deribit, :okex, :ftx]

  config :exvcr,
    filter_request_headers: [
      # GDAX
      "CB-ACCESS-KEY",
      "CB-ACCESS-SIGN",
      "CB-ACCESS-TIMESTAMP",
      "CB-ACCESS-PASSPHRASE",
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
      "OK-ACCESS-PASSPHRASE",
      # Deribit
      "Authorization",
      # FTX
      "FTX-KEY",
      "FTX-SIGN",
      "FTX-TS"
    ],
    filter_sensitive_data: [
      # GDAX
      [pattern: "\"id\":\"[a-z0-9-]{36,36}\"", placeholder: "\"id\":\"***\""],
      [pattern: "\"profile_id\":\"[a-z0-9-]{36,36}\"", placeholder: "\"profile_id\":\"***\""],
      # Binance
      [pattern: "signature=[A-Z0-9]+", placeholder: "signature=***"],
      # FTX
      [pattern: "username\":\"[a-zA-Z0-9@.]+\"", placeholder: "username\":\"***\""]
    ],
    response_headers_blacklist: [
      # Shared
      "Set-Cookie",
      "ETag",
      "cf-request-id",
      "CF-RAY",
      # FTX
      "account-id"
    ]

  config :echo_boy, port: 4100

  config :ex_bitmex, domain: "testnet.bitmex.com"
  config :ex_deribit, domain: "test.deribit.com"
end
