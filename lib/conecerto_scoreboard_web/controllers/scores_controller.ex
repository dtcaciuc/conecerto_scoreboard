defmodule Conecerto.ScoreboardWeb.ScoresController do
  use Conecerto.ScoreboardWeb, :controller

  alias Conecerto.Scoreboard

  plug :put_layout, html: :scores

  @root_font_size 16.0

  def home(%{method: "HEAD"} = conn, _params) do
    send_resp(conn, 200, "OK")
  end

  def home(%{method: "GET"} = conn, _params) do
    render(conn, :home,
      root_font_size: @root_font_size,
      active_tab: "Event",
      radio_frequency: Scoreboard.config(:radio_frequency),
      recent_runs: Scoreboard.list_recent_runs(10),
      last_updated_at: Scoreboard.last_updated_at()
    )
  end

  def raw(conn, _params) do
    render(conn, :raw,
      root_font_size: @root_font_size,
      active_tab: "Raw",
      raw_scores: Scoreboard.list_raw_scores()
    )
  end

  def pax(conn, _params) do
    render(conn, :pax,
      root_font_size: @root_font_size,
      active_tab: "PAX",
      pax_scores: Scoreboard.list_pax_scores()
    )
  end

  def groups(conn, _params) do
    render(conn, :groups,
      root_font_size: @root_font_size,
      active_tab: "Groups",
      groups: Scoreboard.list_all_group_scores()
    )
  end

  def runs(conn, _params) do
    render(conn, :runs,
      root_font_size: @root_font_size,
      active_tab: "Runs",
      drivers: Scoreboard.list_drivers_and_runs()
    )
  end
end
