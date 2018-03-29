defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.0.1",
      elixir: "~> 1.6",
      package: package(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Tai, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:decimal, "~> 1.0"},
      {:ex_gdax, "~> 0.1.2"},
      {:binance, "~> 0.4"},
      {:httpoison, "~> 1.0", override: true},
      {:json, "~> 1.0"},
      {:table_rex, "~> 1.0"},
      {:timex, "~> 3.1"},
      {:websockex, "~> 0.4"},
      {:logger_file_backend, "~> 0.0.10"},
      {:uuid, "~> 1.1"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:cowboy, "~> 1.0.0", only: [:dev, :test]},
      {:echo_boy, "~> 0.1.0", github: "rupurt/echo_boy", only: [:dev, :test]},
      {:exvcr, "~> 0.10.1", only: [:dev, :test]},
      {:plug, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1", only: :test}
    ]
  end

  defp description do
    "A trading toolkit built with Elixir and running on the Erlang virtual machine"
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
