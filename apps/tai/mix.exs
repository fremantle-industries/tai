defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.0.57",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
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
      extra_applications: [:logger, :jason, :tai_events]
    ]
  end

  defp deps do
    [
      {:enumerati, "~> 0.0.6"},
      {:ex2ms, "~> 1.0"},
      {:ex_binance, "~> 0.0.4"},
      # {:ex_bitmex, github: "fremantle-capital/ex_bitmex", branch: "master"},
      {:ex_bitmex, "~> 0.5"},
      # {:ex_deribit, github: "fremantle-capital/ex_deribit", branch: "master"},
      {:ex_deribit, "~> 0.0.7"},
      # {:ex_okex, github: "fremantle-capital/ex_okex", branch: "master"},
      {:ex_okex, "~> 0.4"},
      {:ex_gdax, "~> 0.1.6"},
      # {:ex_huobi, github: "fremantle-capital/ex_huobi", branch: "master"},
      {:ex_huobi, "~> 0.0.2"},
      {:decimal, "~> 1.7"},
      {:httpoison, "~> 1.0"},
      {:juice, "~> 0.0.3"},
      {:table_rex, "~> 3.0"},
      {:timex, "~> 3.6"},
      # Fixes deprecation warnings
      # {:websockex, github: "Azolo/websockex"},
      {:websockex, "~> 0.4"},
      {:confex, "~> 3.4"},
      {:ecto, "~> 3.1"},
      {:jason, "~> 1.1"},
      {:vex, "~> 0.7"},
      {:stored, "~> 0.0.4"},
      # {:tai_events, path: "../../packages/tai_events"},
      {:tai_events, "~> 0.0.1"},
      {:logger_file_backend_with_formatters, "~> 0.0.1", only: [:dev, :test]},
      {:logger_file_backend_with_formatters_stackdriver, "~> 0.0.4", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:echo_boy, "~> 0.6", runtime: false, optional: true},
      {:exvcr, "~> 0.12.1", only: [:dev, :test]},
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
      links: %{"GitHub" => "https://github.com/fremantle-capital/tai"}
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
