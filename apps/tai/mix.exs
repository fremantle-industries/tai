defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.0.75",
      elixir: "~> 1.11",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      package: package(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      mod: {Tai.Application, []},
      start_phases: [venues: []],
      extra_applications: [
        :phoenix_pubsub,
        :logger,
        :iex,
        :jason,
        :tai_events,
        :ecto_term,
        :postgrex
      ]
    ]
  end

  defp deps do
    [
      {:confex, "~> 3.4"},
      {:ecto, "~> 3.6"},
      {:ecto_sql, "~> 3.6"},
      {:ecto_sqlite3, "~> 0.8.0", optional: true},
      # {:ecto_term, github: "fremantle-industries/ecto_term"},
      {:ecto_term, "~> 0.0.1"},
      {:enumerati, "~> 0.0.8"},
      {:ex2ms, "~> 1.0"},
      {:ex_binance, "~> 0.0.10"},
      # {:ex_bitmex, github: "fremantle-industries/ex_bitmex", branch: "main"},
      {:ex_bitmex, "~> 0.6.1"},
      # {:ex_bybit, github: "fremantle-industries/ex_bybit", branch: "main"},
      {:ex_bybit, "~> 0.0.1"},
      {:ex_delta_exchange, "~> 0.0.3"},
      # {:ex_deribit, github: "fremantle-industries/ex_deribit", branch: "main"},
      {:ex_deribit, "~> 0.0.9"},
      # {:ex_ftx, github: "fremantle-industries/ex_ftx", branch: "main"},
      {:ex_ftx, "~> 0.0.13"},
      # {:ex_okex, github: "fremantle-industries/ex_okex", branch: "main"},
      {:ex_okex, "~> 0.6"},
      {:ex_gdax, "~> 0.2"},
      # {:ex_huobi, github: "fremantle-industries/ex_huobi", branch: "main"},
      {:ex_huobi, "~> 0.0.2"},
      {:decimal, "~> 2.0"},
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:juice, "~> 0.0.3"},
      {:murmur, "~> 1.0"},
      {:paged_query, "~> 0.0.2"},
      {:phoenix_pubsub, "~> 2.0"},
      {:polymorphic_embed, "~> 2.0"},
      {:poolboy, "~> 1.5.1"},
      {:postgrex, "~> 0.15", optional: true},
      {:table_rex, "~> 3.0"},
      # {:tai_events, path: "../../packages/tai_events"},
      {:tai_events, "~> 0.0.2"},
      {:telemetry, "~> 0.4 or ~> 1.0"},
      {:timex, "~> 3.6"},
      {:stored, "~> 0.0.8"},
      {:vex, "~> 0.7"},
      {:websockex, "~> 0.4.3"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.13.0", only: [:dev, :test]},
      {:logger_file_backend_with_formatters, "~> 0.0.1", only: [:dev, :test]},
      {:logger_file_backend_with_formatters_stackdriver, "~> 0.0.4", only: [:dev, :test]},
      {:echo_boy, "~> 0.6", runtime: false, optional: true},
      {:mock, "~> 0.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},

      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false} # TODO: remove after dialyzer umbrella support is added
    ]
  end

  defp description do
    "A composable, real time, market data and trade execution toolkit"
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Alex Kwiatkowski"],
      links: %{"GitHub" => "https://github.com/fremantle-industries/tai"}
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
