defmodule Conecerto.Scoreboard.EnvConfig do
  def get(key) do
    Application.fetch_env!(:conecerto_scoreboard, Conecerto.Scoreboard)[key]
  end
end
