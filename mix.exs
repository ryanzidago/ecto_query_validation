defmodule EctoQueryRuntimeChecks.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_query_runtime_checks,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp description do
    "Runtime checks for executed Ecto queries, plus a Repo.prepare_query/3 helper."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/ryanzidago/ecto_query_runtime_checks"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end
end
