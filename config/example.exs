use Mix.Config

config :tai, send_orders: false
config :tai, :broadcast_change_set, true

config :tai,
  fleets: %{
    log_spread: %{
      advisor: Examples.LogSpread.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      quotes: "binance.btc_usdt gdax.btc_usd"
    },
    ping_pong: %{
      advisor: Examples.PingPong.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      quotes: "bitmex.xbtusd",
      config:
        {Examples.PingPong.Config,
         %{
           product: {{:bitmex, :xbtusd}, :product},
           fee: {{:bitmex, :xbtusd, :main}, :fee},
           max_qty: {5, :decimal}
         }}
    }
  }

config :tai,
  venues: %{
    bitmex: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Bitmex,
      products: "xbtusd",
      quote_depth: 3,
      credentials: %{
        main: %{
          api_key: {:system_file, "BITMEX_API_KEY"},
          api_secret: {:system_file, "BITMEX_API_SECRET"}
        }
      },
      broadcast_change_set: true,
      opts: %{
        autocancel: %{ping_interval_ms: 15_000, cancel_after_ms: 60_000}
      }
    ],
    okex: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.OkEx,
      products: "eth_usd_190419 eth_usd_190426 eth_usd_190628",
      credentials: %{
        main: %{
          api_key: {:system_file, "OKEX_API_KEY"},
          api_secret: {:system_file, "OKEX_API_SECRET"},
          api_passphrase: {:system_file, "OKEX_API_PASSPHRASE"}
        }
      }
    ],
    ftx: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Ftx,
      products: "btc/usd btc-perp"
    ],
    huobi: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Huobi,
      products: "btc200626 ltc200626 eth200626"
    ],
    binance: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Binance,
      products: "btc_usdt ltc_usdt eth_usdt",
      credentials: %{
        main: %{
          api_key: {:system_file, "BINANCE_API_KEY"},
          secret_key: {:system_file, "BINANCE_API_SECRET"}
        }
      }
    ],
    deribit: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Deribit,
      products: "btc_perpetual",
      credentials: %{
        main: %{
          client_id: {:system_file, "DERIBIT_CLIENT_ID"},
          client_secret: {:system_file, "DERIBIT_CLIENT_SECRET"}
        }
      }
    ],
    gdax: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Gdax,
      products: "btc_usd ltc_usd eth_usd",
      credentials: %{
        main: %{
          api_url: "https://api.pro.coinbase.com",
          api_key: {:system_file, "GDAX_API_KEY"},
          api_secret: {:system_file, "GDAX_API_SECRET"},
          api_passphrase: {:system_file, "GDAX_API_PASSPHRASE"}
        }
      }
    ]
  }
