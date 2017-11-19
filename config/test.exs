use Mix.Config

config :tai, exchanges: %{
  test_exchange_a: [
    Tai.Exchanges.Adapters.Test
  ],
  test_exchange_b: [
    Tai.Exchanges.Adapters.Test,
    config_key: "some_key"
  ]
}
