use Mix.Config

# Cluster
config :libcluster,
  topologies: [
    tai: [
      strategy: Cluster.Strategy.Gossip
    ]
  ]

# Tai
config :tai, send_orders: false

config :tai,
  fleets: %{
    log_spread: %{
      advisor: Examples.LogSpread.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      market_streams: "binance.btc_usdt gdax.btc_usd"
    }
  }

config :tai,
  venues: %{
    binance: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Binance,
      products: "btc_usdt ltc_usdt eth_usdt"
    ],
    gdax: [
      start_on_boot: true,
      adapter: Tai.VenueAdapters.Gdax,
      products: "btc_usd ltc_usd eth_usd",
      market_streams: "* -ltc_usd"
    ]
  }
