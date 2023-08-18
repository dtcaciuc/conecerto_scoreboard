defmodule Conecerto.Scoreboard.Repo do
  use Ecto.Repo,
    otp_app: :conecerto_scoreboard,
    adapter: Ecto.Adapters.SQLite3
end
