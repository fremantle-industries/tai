use Mix.Config

config :logger_json, :backend, metadata: :all
config :logger, :file_log, path: "./log/#{Mix.env()}.log", metadata: [:tid]

config :logger,
  backends: [
    {LoggerFileBackend, :file_log},
    LoggerJSON
  ]

if System.get_env("DEBUG") == "true" do
  config :logger, :file_log, level: :debug
else
  config :logger, :file_log, level: :info
end

import_config "#{Mix.env()}.exs"
