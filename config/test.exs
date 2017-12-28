use Mix.Config

config :ex_gdax,      api_key:         System.get_env("GDAX_API_KEY"),
                      api_secret:      System.get_env("GDAX_API_SECRET"),
                      api_passphrase:  System.get_env("GDAX_API_PASSPHRASE")

config :ex_bitstamp,  api_key:         System.get_env("BITSTAMP_API_KEY"),
                      api_secret:      System.get_env("BITSTAMP_API_SECRET"),
                      customer_id:     System.get_env("BITSTAMP_CUSTOMER_ID")

config :tai,          exchanges: %{
                        test_exchange_a: Tai.Exchanges.Adapters.Test,
                        test_exchange_b: Tai.Exchanges.Adapters.Test
                      }

config :tai,          strategies: %{
                        test_strategy_a: Tai.Strategies.Info,
                        test_strategy_b: Tai.Strategies.Info
                      }
