use Mix.Config

config :logger,
  backends: [{LoggerFileBackend, :file_log}],
  utc_log: true

log_format = "$dateT$time [$level]$levelpad $metadata$message\n"

config :logger, :file_log,
  path: "./log/#{Mix.env()}.log",
  format: log_format,
  metadata: [:pname]

config :logger, :console, format: log_format

if System.get_env("DEBUG") == "true" do
  config :logger, :file_log, level: :debug
else
  config :logger, :file_log, level: :info
end

import_config "#{Mix.env()}.exs"
