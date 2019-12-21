defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.0.45",
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
      mod: {Tai, []},
      extra_applications: [:logger, :jason]
    ]
  end

  defp deps do
    [
      {:enumerati, "~> 0.0.3"},
      {:ex_binance, "~> 0.0.4"},
      # {:ex_bitmex, github: "fremantle-capital/ex_bitmex"},
      {:ex_bitmex, "~> 0.4"},
      # {:ex_okex, path: "../../../ex_okex"},
      # {:ex_okex, github: "fremantle-capital/ex_okex", branch: "master"},
      {:ex_okex, "~> 0.3"},
      {:ex_gdax, "~> 0.1.6"},
      {:decimal, "~> 1.7"},
      {:httpoison, "~> 1.0"},
      {:juice, "~> 0.0.3"},
      {:table_rex, "~> 2.0"},
      {:timex, "~> 3.6"},
      # Fixes deprecation warnings
      # {:websockex, github: "Azolo/websockex"},
      {:websockex, "~> 0.4"},
      {:confex, "~> 3.4"},
      {:ecto, "~> 3.1"},
      {:jason, "~> 1.1"},
      {:vex, "~> 0.7"},
      {:stored, "~> 0.0.2"},
      {:logger_file_backend_with_formatters, "~> 0.0.1", only: [:dev, :test]},
      {:logger_file_backend_with_formatters_stackdriver, "~> 0.0.4", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:echo_boy, "~> 0.6.0", only: [:dev, :test]},
      {:exvcr, "~> 0.11.0", only: [:dev, :test]},
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
