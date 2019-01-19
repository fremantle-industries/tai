defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.0.12",
      elixir: "~> 1.7",
      package: package(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      mod: {Tai, []},
      extra_applications: [:logger, :jason, :logger_json]
    ]
  end

  defp deps do
    [
      {:binance, "~> 0.6.0"},
      {:ex_bitmex, "~> 0.0.5"},
      {:decimal, "~> 1.6.0"},
      {:ex_gdax, "~> 0.1.4"},
      {:ex_poloniex, "~> 0.0.2"},
      {:httpoison, "~> 1.0"},
      {:juice, "~> 0.0.3"},
      {:table_rex, "~> 2.0"},
      {:timex, "~> 3.1"},
      {:uuid, "~> 1.1"},
      {:websockex, "~> 0.4.0"},
      {:confex, "~> 3.4.0"},
      {:logger_file_backend, "~> 0.0.10", only: [:dev, :test]},
      {:logger_json, "~> 3.0.0", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:cowboy, "~> 1.1.2", only: [:dev, :test]},
      {:plug_cowboy, "~> 1.0.0", only: [:dev, :test]},
      {:plug, "~> 1.7.0", only: [:dev, :test]},
      {:echo_boy, github: "rupurt/echo_boy", only: [:dev, :test]},
      {:exvcr, "~> 0.10.2", only: [:dev, :test]},
      {:excoveralls, "~> 0.8", only: :test},
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 0.9", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
      "test.watch": "test.watch --no-start"
    ]
  end

  defp description do
    "A trading toolkit built with Elixir that runs on the Erlang virtual machine"
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Alex Kwiatkowski"],
      links: %{"GitHub" => "https://github.com/fremantle-capital/tai"}
    }
  end

  defp elixirc_paths(:dev) do
    if System.get_env("EXAMPLES") == "true" do
      ["lib", "examples"]
    else
      ["lib"]
    end
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "examples"]
  defp elixirc_paths(_), do: ["lib"]
end
