defmodule TaiEvents.MixProject do
  use Mix.Project

  def project do
    [
      app: :tai_events,
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      package: package(),
      start_permanent: Mix.env() == :prod,
      description: description(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {TaiEvents.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "An event bus with events that can be serialized into JSON"
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Alex Kwiatkowski"],
      links: %{"GitHub" => "https://github.com/fremantle-capital/tai/tree/master/apps/tai_events"}
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test/tai_events_support"]
  defp elixirc_paths(_), do: ["lib"]
end
