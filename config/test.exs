use Mix.Config

config :ex_gdax, api_key:        System.get_env("GDAX_API_KEY"),
                 api_secret:     System.get_env("GDAX_API_SECRET"),
                 api_passphrase: System.get_env("GDAX_API_PASSPHRASE")

config :tai,  exchanges: %{
                test_exchange_a: [
                  Tai.Exchanges.Adapters.Test
                ],
                test_exchange_b: [
                  Tai.Exchanges.Adapters.Test,
                  config_key: "some_key"
                ]
              }
