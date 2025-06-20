# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :conecerto_scoreboard,
  namespace: Conecerto.Scoreboard,
  ecto_repos: [Conecerto.Scoreboard.Repo]

config :conecerto_scoreboard, Conecerto.Scoreboard,
  watcher: Conecerto.Scoreboard.MJ.Watcher,
  uploader: Conecerto.Scoreboard.Uploader

# Configures the endpoint
config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: Conecerto.ScoreboardWeb.ErrorHTML, json: Conecerto.ScoreboardWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Conecerto.Scoreboard.PubSub,
  live_view: [signing_salt: "cBc7Yzig"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.10",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
