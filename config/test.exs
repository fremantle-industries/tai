use Mix.Config

config :ex_gdax,      api_key:         System.get_env("GDAX_API_KEY"),
                      api_secret:      System.get_env("GDAX_API_SECRET"),
                      api_passphrase:  System.get_env("GDAX_API_PASSPHRASE")

config :ex_bitstamp,  api_key:         System.get_env("BITSTAMP_API_KEY"),
                      api_secret:      System.get_env("BITSTAMP_API_SECRET"),
                      customer_id:     System.get_env("BITSTAMP_CUSTOMER_ID")

config :tai,          order_book_feeds: %{
                        test_feed_a: [
                          adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
                          order_books: [:btcusd, :ltcusd]
                        ],
                        test_feed_b: [
                          adapter: Tai.ExchangeAdapters.Test.OrderBookFeed,
                          order_books: [:ethusd, :ltcusd]
                        ]
                      }

config :tai,          exchanges: %{
                        test_exchange_a: Tai.ExchangeAdapters.Test,
                        test_exchange_b: Tai.ExchangeAdapters.Test
                      }

config :tai,          strategies: %{
                        test_strategy_a: Tai.Strategies.Info,
                        test_strategy_b: Tai.Strategies.Info
                      }
