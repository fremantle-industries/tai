use Mix.Config

config :tai, accounts: %{
  test_account_a: [
    Tai.Adapters.Test
  ],
  test_account_b: [
    Tai.Adapters.Test,
    config_key: "some_key"
  ]
}
