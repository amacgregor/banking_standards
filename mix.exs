defmodule BankingStandards.MixProject do
  use Mix.Project

  def project do
    [
      app: :banking_standards,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Banking Standards
    """
  end

  defp package do
    [
      name: :banking_standards,
      licenses: ["MIT"],
      maintainers: ["Allan MacGregor"],
      links: %{
        "GitHub" => "https://github.com/amacgregor/banking_standards"
      }
    ]
  end
end
