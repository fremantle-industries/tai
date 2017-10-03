use Mix.Config

config :tai, accounts: %{
  bitmex: [
    Tai.Adapters.Bitmex,
    api_key: System.get_env("BITMEX_API_KEY"),
    secret: System.get_env("BITMEX_SECRET")
  ]
}
