defmodule Conecerto.ScoreboardWeb.ScoresController do
  use Conecerto.ScoreboardWeb, :controller

  alias Conecerto.Scoreboard
  alias Conecerto.ScoreboardWeb.Brands

  plug :put_layout, html: :scores

  @root_font_size 16.0

  def home(%{method: "HEAD"} = conn, _params) do
    send_resp(conn, 200, "OK")
  end

  def home(%{method: "GET"} = conn, _params) do
    assigns =
      get_assigns(
        active_tab: "Event",
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

  defp get_assigns(extra) do
    [
      root_font_size: @root_font_size,
      event_name: Scoreboard.config(:event_name),
      last_updated_at: Scoreboard.last_updated_at(),
      organizer: Brands.get_organizer(),
      sponsors: Brands.get_sponsors()
    ]
    |> Keyword.merge(extra)
  end
end
