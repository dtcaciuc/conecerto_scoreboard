defmodule Conecerto.ScoreboardWeb.ExplorerController do
  use Conecerto.ScoreboardWeb, :controller

  alias Conecerto.Scoreboard
  alias Conecerto.ScoreboardWeb.Brands

  plug :put_layout, html: :explorer

  @root_font_size 16.0

  def index(%{method: "HEAD"} = conn, _params) do
    send_resp(conn, 200, "OK")
  end

  def index(%{method: "GET"} = conn, _params) do
    redirect(conn, to: ~p"/event")
  end

  def event(%{method: "GET"} = conn, _params) do
    assigns =
      get_assigns(
        active_tab: "Event",
        show_recent_runs?: Scoreboard.config(:explorer_show_recent_runs?),
        radio_frequency: Scoreboard.config(:radio_frequency),
        recent_runs: Scoreboard.list_recent_runs(10)
      )

    render(conn, :home, assigns)
  end

  def raw(conn, _params) do
    assigns =
      get_assigns(
        active_tab: "Raw",
        raw_scores: Scoreboard.list_raw_scores()
      )

    render(conn, :raw, assigns)
  end

  def pax(conn, _params) do
    assigns =
      get_assigns(
        active_tab: "PAX",
        pax_scores: Scoreboard.list_pax_scores()
      )

    render(conn, :pax, assigns)
  end

  def groups(conn, _params) do
    assigns =
      get_assigns(
        active_tab: "Groups",
        groups: Scoreboard.list_all_group_scores()
      )

    render(conn, :groups, assigns)
  end

  def runs(conn, _params) do
    assigns =
      get_assigns(
        active_tab: "Runs",
        drivers: Scoreboard.list_drivers_and_runs()
      )

    render(conn, :runs, assigns)
  end

  def cones(conn, _params) do
    assigns =
      get_assigns(
        active_tab: "Δs",
        drivers: Scoreboard.list_total_cones()
      )

    render(conn, :cones, assigns)
  end

  defp get_assigns(extra) do
    [
      root_font_size: @root_font_size,
      colors: Conecerto.Scoreboard.config(:explorer_colors),
      event_name: Scoreboard.config(:event_name) || format_date(Scoreboard.config(:event_date)),
      last_updated_at: Scoreboard.last_updated_at(),
      organizer: Brands.get_organizer(),
      sponsors: Brands.get_sponsors()
    ]
    |> Keyword.merge(extra)
  end

  defp format_date(date),
    do: String.replace(date, "_", "/")
end
