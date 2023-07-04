defmodule Examples.MixProject do
  use Mix.Project

  def project do
    [
      app: :examples,
      version: "0.0.75",
      elixir: "~> 1.11",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      mod: {Examples.Application, []},
      extra_applications: [:logger, :tai]
    ]
  end

  defp deps do
    [
      {:tai, in_umbrella: true},
      {:libcluster, "~> 3.2"},

      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false} # TODO: remove after dialyzer umbprella support is added
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
