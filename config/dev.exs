use Mix.Config

config :ex_gdax,      api_key:         System.get_env("GDAX_API_KEY"),
                      api_secret:      System.get_env("GDAX_API_SECRET"),
                      api_passphrase:  System.get_env("GDAX_API_PASSPHRASE")

config :ex_bitstamp,  api_key:         System.get_env("BITSTAMP_API_KEY"),
                      api_secret:      System.get_env("BITSTAMP_API_SECRET"),
                      customer_id:     System.get_env("BITSTAMP_CUSTOMER_ID")

config :tai,          order_book_feeds: %{
                        gdax: [
                          adapter: Tai.ExchangeAdapters.Gdax.OrderBookFeed,
                          order_books: [:btcusd, :ltcusd, :ethusd]
                        ]
                      }

config :tai,          exchanges: %{
                        gdax: Tai.ExchangeAdapters.Gdax,
                        bitstamp: Tai.ExchangeAdapters.Bitstamp
                      }

config :tai,          advisors: %{
                        info: Support.Advisors.Info
                      }
