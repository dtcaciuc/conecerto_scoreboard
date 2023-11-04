defmodule Conecerto.ScoreboardWeb.BrandAssets do
  @behaviour Plug

  alias Conecerto.Scoreboard

  @impl true
  def init(_opts) do
    Plug.Static.init(at: "/brands", from: nil)
  end

  @impl true
  def call(conn, opts) do
    Plug.Static.call(conn, %{opts | from: Scoreboard.config(:brands_dir)})
  end
end
