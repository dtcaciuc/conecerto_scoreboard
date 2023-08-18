import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :conecerto_scoreboard, Conecerto.Scoreboard.Repo,
  database: Path.expand("../scoreboard_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "s55wO4EN/anFccVU3tDUT6xGQzD+skcYEMZ4wpllEN8PZ+TNzwl14vWWTBYBDLqc",
  server: false

# In test we don't send emails.
config :conecerto_scoreboard, Conecerto.Scoreboard.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
