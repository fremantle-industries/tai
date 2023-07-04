defmodule TaiMonorepo.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.0.75",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:echo_boy, :ex_unit, :mix],
        ignore_warnings: ".dialyzer_ignore.exs",
        paths: [
          "_build/dev/lib/tai/ebin",
          "_build/dev/lib/examples/ebin"
        ]
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp deps do
    [
      {:excoveralls, "~> 0.8", only: :test},
      {:ex_unit_notifier, "~> 1.0", only: :test},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:licensir, "~> 0.6", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "tai.gen.migration", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "test.watch": ["ecto.create --quiet", "ecto.migrate", "test.watch"]
    ]
  end
end
