defmodule TaiMonorepo.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.0.39",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
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
      {:ex_unit_notifier, "~> 0.1", only: :test},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.9", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
      "test.watch": "test.watch --no-start"
    ]
  end
end
