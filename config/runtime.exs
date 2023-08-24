import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/conecerto_scoreboard start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint, server: true
end

config :conecerto_scoreboard, Conecerto.Scoreboard,
  event_date: System.get_env("EVENT_DATE"),
  tv_refresh_interval: String.to_integer(System.get_env("TV_REFRESH_INTERVAL", "10")) * 1_000,
  tv_font_size: String.to_float(System.get_env("TV_FONT_SIZE", "17.5")),
  announce_font_size: String.to_float(System.get_env("ANNOUNCE_FONT_SIZE", "16.5")),
  radio_frequency: System.get_env("RADIO_FREQUENCY"),
  live_ftp_host: System.get_env("LIVE_FTP_HOST"),
  live_ftp_user: System.get_env("LIVE_FTP_USER"),
  live_ftp_pass: System.get_env("LIVE_FTP_PASS"),
  live_ftp_path: System.get_env("LIVE_FTP_PATH", "/"),
  mj_dir: System.get_env("MJ_DIR", "c:/mjtiming"),
  mj_debounce_interval: String.to_integer(System.get_env("MJ_DEBOUNCE_INTERVAL", "1000"))

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /etc/conecerto_scoreboard/conecerto_scoreboard.db
      """

  config :conecerto_scoreboard, Conecerto.Scoreboard.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "80")

  config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
    # Binding to loopback ipv4 address prevents access from other machines.
    # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
    url: [host: host, port: 80, scheme: "http"],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  # config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
  #   url: [host: host, port: 443, scheme: "https"],
  #   http: [
  #     # Enable IPv6 and bind on all interfaces.
  #     # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
  #     # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
  #     # for details about using IPv6 vs IPv4 and loopback vs public addresses.
  #     ip: {0, 0, 0, 0, 0, 0, 0, 0},
  #     port: port
  #   ],
  #   secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :conecerto_scoreboard, Conecerto.Scoreboard.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
