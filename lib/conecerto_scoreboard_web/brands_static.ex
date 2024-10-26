defmodule Conecerto.ScoreboardWeb.Brands.Static do
  @behaviour Plug

  alias Conecerto.Scoreboard
  alias Conecerto.ScoreboardWeb.Brands

  @impl true
  def init(_opts) do
    Plug.Static.init(at: Brands.root_path(), from: nil)
  end

  @impl true
  def call(conn, opts) do
    Plug.Static.call(conn, %{opts | from: Scoreboard.config(:brands_dir)})
  end
end
