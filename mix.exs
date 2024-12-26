defmodule BankingStandards.MixProject do
  use Mix.Project

  def project do
    [
      app: :banking_standards,
      version: app_version(),
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
    "Building the foundation for seamless financial transactions in Elixir."
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

  defp app_version do
    # get git version
    {description, 0} = System.cmd("git", ~w[describe]) # => returns something like: v1.0-231-g1c7ef8b
    _git_version = String.trim(description)
                    |> String.split("-")
                    |> Enum.take(2)
                    |> Enum.join("-")
                    |> String.replace_leading("v", "")
  end
end
