use Mix.Config

config :tai, send_orders: false
config :tai, :broadcast_change_set, true

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
      products: "btc/usd btc-perp",
      credentials: %{
        main: %{
          api_key: {:system_file, "FTX_API_KEY"},
          api_secret: {:system_file, "FTX_API_SECRET"}
        }
      }
    ],
    binance: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Binance,
      products: "btc_usdt ltc_usdt eth_usdt"
    ]
  }
