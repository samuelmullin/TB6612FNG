defmodule TB6612FNG.MixProject do
  use Mix.Project

  def project do
    [
      app: :tb6612fng,
      version: "0.1.0",
      elixir: "~> 1.13",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:circuits_gpio, "~> 1.0"},
      {:pigpiox, "~> 0.1"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [ "README.md"]
    ]
  end

  defp package do
    [
      name: "TB6612FNG",
      description:
        "A driver for working with the TB6612FNG",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/samuelmullin/tb6612fng"}
    ]
  end
end
