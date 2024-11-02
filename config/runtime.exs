import Config
import Conecerto.Scoreboard.ConfigUtils

if config_env() != :test do
  event_date = System.get_env("EVENT_DATE", Conecerto.Scoreboard.Datetime.today_str())

  event_name =
    Conecerto.Scoreboard.Events.get_event_name(System.get_env("EVENT_SCHEDULE"), event_date)

  config :conecerto_scoreboard, Conecerto.Scoreboard,
    event_date: event_date,
    event_name: System.get_env("EVENT_NAME", event_name),
    tv_refresh_interval: String.to_integer(System.get_env("TV_REFRESH_INTERVAL", "10")) * 1_000,
    tv_font_size: parse_float!(System.get_env("TV_FONT_SIZE", "17.75")),
    announce_font_size: parse_float!(System.get_env("ANNOUNCE_FONT_SIZE", "16.5")),
    radio_frequency: System.get_env("RADIO_FREQUENCY"),
    live_ftp_host: System.get_env("LIVE_FTP_HOST"),
    live_ftp_user: System.get_env("LIVE_FTP_USER"),
    live_ftp_pass: System.get_env("LIVE_FTP_PASS"),
    live_ftp_path: System.get_env("LIVE_FTP_PATH", "/"),
    mj_dir: System.get_env("MJ_DIR", "c:/mjtiming"),
    mj_debounce_interval: String.to_integer(System.get_env("MJ_DEBOUNCE_INTERVAL", "1000")),
    mj_poll_changes?: System.get_env("MJ_POLL_CHANGES") != nil,
    mj_poll_interval: String.to_integer(System.get_env("MJ_POLL_INTERVAL", "1000")),
    brands_dir: System.get_env("BRANDS_DIR")

  database_path =
    System.get_env("DATABASE_PATH") ||
      Path.join(System.tmp_dir(), "conecerto_scoreboard_#{config_env()}.db")

  config :conecerto_scoreboard, Conecerto.Scoreboard.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PHX_PORT") || "80")

  # Live endpoints will be unsecured and used on a local network so there's
  # no harm generating a random key base if it's not specified.
  secret_key_base = System.get_env("SECRET_KEY_BASE") || generate_secret_key_base()

  config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint,
    url: [host: host, port: port, scheme: "http"],
    # Binding to loopback ipv4 address prevents access from other machines.
    # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
    # http: [ip: {127, 0, 0, 1}, port: 4000],
    http: [ip: {0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  if System.get_env("PHX_SERVER") do
    config :conecerto_scoreboard, Conecerto.ScoreboardWeb.Endpoint, server: true
  end
end
