defmodule LazyTeamcity.MixProject do
  use Mix.Project

  def project do
    [
      app: :lazy_teamcity,
      version: "0.1.0",
      elixir: "~> 1.18.2",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [mod: {LazyTeamcity.Application, []}, extra_applications: [:logger, :timex]]
  end

  defp aliases do
    [run: "run --no-halt"]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:ratatouille, "~> 0.5.1"},
      {:tesla, "~> 1.14"},
      {:jason, "~> 1.4"},
      {:finch, "~> 0.19.0"},
      {:guarded_struct, "~> 0.0.4"},
      {:tesla_middleware_xml, "~> 2.0.0"},
      {:saxy, "~> 1.6"},
      {:timex, "~> 3.7"},
      {:recode, "~> 0.7.3"}
    ]
  end
end
