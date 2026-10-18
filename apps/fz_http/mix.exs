defmodule FzHttp.MixProject do
  use Mix.Project

  def project do
    [
      app: :fz_http,
      version: version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.20",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      aliases: aliases(),
      deps: deps()
    ]
  end

  def version do
    # Use dummy version for dev and test
    System.get_env("VERSION", "0.0.0+git.0.deadbeef")
  end

  def application do
    [
      mod: {FzHttp.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix/Plug deps
      {:plug, "~> 1.20.3"},
      {:plug_cowboy, "~> 2.9.0"},
      {:phoenix, "~> 1.8.15"},
      {:phoenix_ecto, "~> 4.7.0"},
      {:phoenix_html, "~> 4.3.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_pubsub, "~> 2.4.1"},
      {:phoenix_live_view, "~> 1.2.12"},
      {:phoenix_live_dashboard, "~> 0.9.1"},
      {:phoenix_live_reload, "~> 1.7.0", only: :dev},
      {:phoenix_swoosh, "~> 1.2.1"},
      {:gettext, "~> 1.0.2"},
      {:file_size, "~> 3.0.1"},

      # Ecto-related deps
      {:postgrex, "~> 0.22.4"},
      # FileSize's pre-3.0 upper bound is stale; its Decimal API usage is covered
      # by the byte-formatting regression tests alongside Ecto 3.14.
      {:decimal, "~> 3.2.0", override: true},
      {:ecto_sql, "~> 3.14.0"},
      # Security backports retain the existing AES-GCM storage format.
      {:cloak, path: "../../vendor/security/cloak", override: true},
      {:cloak_ecto, path: "../../vendor/security/cloak_ecto"},
      # The upstream structured-header serializer fix is not in a Hex release yet.
      {:cowlib,
       github: "ninenines/cowlib", ref: "4401b858f2229abb3ea115c60924f6c77e5f8aa3", override: true},
      # The test-only Bypass copy uses Ranch 2's listener lifecycle.
      {:ranch, "~> 2.3.0", override: true},

      # Auth-related deps
      {:guardian, "~> 2.5.0"},
      {:guardian_db, "~> 3.0.0"},
      # Older optional constraints in Phoenix.Swoosh and Wallaby otherwise
      # retain Hackney 1.x; both adapters use the compatible request API.
      {:hackney, "~> 4.8.5", override: true},
      {:httpoison, "~> 3.0.0", only: :test, override: true},
      {:openid_connect, "~> 1.0.1"},
      # Preserve Firezone-specific SAML error handling and provider refresh support.
      {:esaml,
       github: "firezone/esaml", ref: "4294a3ac5262582144e117c10a1537287b6c1fe8", override: true},
      {:samly, github: "firezone/samly", ref: "4603438ed4a95ed74d6c0232676c24d097e2feec"},
      {:ueberauth, "~> 0.11.0"},
      {:ueberauth_identity, "~> 0.4.2"},
      {:argon2_elixir, "~> 4.1.3"},
      {:nimble_totp, "~> 1.0.0"},

      # Other deps
      {:remote_ip, "~> 1.2.0"},
      {:telemetry, "~> 1.4.2"},
      # Used in Swoosh SMTP adapter
      {:gen_smtp, "~> 1.3.0"},
      {:posthog, "~> 2.16.2"},

      # Runtime debugging
      {:recon, "~> 2.5.6"},
      {:observer_cli, "~> 2.0.0"},

      # Test and dev deps
      {:bypass, path: "../../vendor/security/bypass", only: :test},
      {:wallaby, "~> 0.31.0", only: :test},
      {:bureaucrat, "~> 0.2.10", only: :test},
      {:floki, "~> 0.38.4"},
      {:lazy_html, "~> 0.1.13", only: :test}
    ]
  end

  defp aliases do
    [
      "assets.build": ["cmd cd assets && npm ci && npm run deploy"],
      "ecto.seed": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
