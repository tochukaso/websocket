defmodule Websocket.MixProject do
  use Mix.Project

  def project do
    [
      app: :websocket,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      default_release: :websocket,
      releases: [
        websocket: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent],
          steps: [:assemble, :tar],
          cookie: "websocket"
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Websocket.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:configparser_ex, "~> 4.0.0"},
      {:cors_plug, "~> 2.0.2"},
      {:credo, "~> 1.4.0", only: [:dev], runtime: false},
      {:ex_aws, "~> 2.1.4", override: true},
      {:ex_aws_dynamo, "~> 3.0.3"},
      {:ex_aws_sqs, "~> 3.2.1"},
      {:jason, "~> 1.0"},
      {:hackney, "~> 1.16.0"},
      {:httpoison, "~> 1.7.0"},
      {:gettext, "~> 0.11"},
      {:libcluster, "~> 3.2.1"},
      {:mnesiac, "~> 0.3.8"},
      {:open_api_spex, "~> 3.7.0"},
      {:phoenix, "~> 1.5.4"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.2"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 4.0.1", override: true},
      {:saxy, "~> 1.2.0"},
      {:sweet_xml, "~> 0.6.6"},
      {:timex, "~> 3.6.2"},
      {:uuid, "~> 1.1.8"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"]
    ]
  end
end
