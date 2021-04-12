defmodule EctoStreamFactory.MixProject do
  use Mix.Project

  @project_url "https://github.com/ibarchenkov/ecto_stream_factory"

  def project do
    [
      app: :ecto_stream_factory,
      version: "0.2.0",
      elixir: ">= 1.10.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),

      # Hex
      description: "A factory library for property-based and regular tests",
      package: package(),

      # Docs
      name: "EctoStreamFactory",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:stream_data, "~> 0.5"},
      {:ecto_sql, "~> 3.0", optional: true},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs do
    [
      source_url: @project_url,
      extras: ["README.md"],
      main: "readme"
    ]
  end

  defp package do
    [
      maintainers: ["Igor Barchenkov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @project_url,
        "Documentation" => "https://hexdocs.pm/ecto_stream_factory"
      }
    ]
  end
end
