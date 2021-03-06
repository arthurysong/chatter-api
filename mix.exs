defmodule Websocket.MixProject do
  use Mix.Project

  def project do
    [
      app: :websocket,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug_cowboy, :corsica],
      mod: {Websocket.Application, []},
      env: [db_host: "localhost"],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:mix_docker, "~> 0.5.0"},
      {:gen_registry, "~> 1.0"},
      {:httpoison, "~>1.8"},
      {:uuid, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 3.1"},
      {:cowboy, "~> 2.4"},
      {:plug, "~> 1.7"},
      {:corsica, "~> 1.0"},
      {:amqp, "~> 1.0"},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
