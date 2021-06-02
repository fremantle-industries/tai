defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.0.66",
      elixir: "~> 1.10",
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
      extra_applications: [:logger, :iex, :jason, :tai_events]
    ]
  end

  defp deps do
    [
      {:confex, "~> 3.4"},
      {:ecto, "~> 3.1"},
      {:enumerati, "~> 0.0.8"},
      {:ex2ms, "~> 1.0"},
      {:ex_binance, "~> 0.0.8"},
      # {:ex_bitmex, github: "fremantle-capital/ex_bitmex", branch: "master"},
      {:ex_bitmex, "~> 0.6.1"},
      # {:ex_deribit, github: "fremantle-capital/ex_deribit", branch: "master"},
      {:ex_deribit, "~> 0.0.9"},
      # {:ex_ftx, github: "fremantle-capital/ex_ftx", branch: "main"},
      {:ex_ftx, "~> 0.0.11"},
      # {:ex_okex, github: "fremantle-capital/ex_okex", branch: "master"},
      {:ex_okex, "~> 0.6"},
      {:ex_gdax, "~> 0.2"},
      # {:ex_huobi, github: "fremantle-capital/ex_huobi", branch: "master"},
      {:ex_huobi, "~> 0.0.2"},
      {:decimal, "~> 2.0"},
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:juice, "~> 0.0.3"},
      {:poolboy, "~> 1.5.1"},
      {:table_rex, "~> 3.0"},
      # {:tai_events, path: "../../packages/tai_events"},
      {:tai_events, "~> 0.0.1"},
      {:telemetry, "~> 0.4"},
      {:timex, "~> 3.6"},
      {:stored, "~> 0.0.4"},
      {:vex, "~> 0.7"},
      {:websockex, "~> 0.4.3"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:exvcr, "~> 0.12.1", only: [:dev, :test]},
      {:logger_file_backend_with_formatters, "~> 0.0.1", only: [:dev, :test]},
      {:logger_file_backend_with_formatters_stackdriver, "~> 0.0.4", only: [:dev, :test]},
      {:echo_boy, "~> 0.6", runtime: false, optional: true},
      {:mock, "~> 0.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
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
