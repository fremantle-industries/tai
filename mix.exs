defmodule Tai.Mixfile do
  use Mix.Project

  def project do
    [
      app: :tai,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
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
      {:httpoison, "~> 0.13"},
      {:json, "~> 1.0"},
      {:websockex, "~> 0.4"},
      {:poloniex, path: "~/workspace/fremantle_capital/poloniex_elixir"}
    ]
  end
end
