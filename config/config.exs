use Mix.Config

config :logger,
  backends: [{LoggerFileBackendWithFormatters, :file_log}],
  utc_log: true

config :logger, :file_log, path: "./log/#{Mix.env()}.log"

if System.get_env("DEBUG") == "true" do
  config :logger, :file_log, level: :debug
else
  config :logger, :file_log, level: :info
end

import_config "#{Mix.env()}.exs"
