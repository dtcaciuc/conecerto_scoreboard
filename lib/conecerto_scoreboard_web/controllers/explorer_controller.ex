defmodule Conecerto.ScoreboardWeb.ExplorerController do
  use Conecerto.ScoreboardWeb, :controller

  alias Conecerto.Scoreboard
  alias Conecerto.ScoreboardWeb.Brands
  alias Conecerto.ScoreboardWeb.CourseMaps

  plug :put_layout,
       [html: {Conecerto.ScoreboardWeb.Layouts, :explorer}]
       when action not in [:collated]

  plug :put_layout, false when action in [:collated]

  @root_font_size 16.0

  def index(%{method: "HEAD"} = conn, _params) do
    send_resp(conn, 200, "OK")
  end

  def index(%{method: "GET"} = conn, _params) do
    redirect(conn, to: ~p"/event")
  end

  def event(%{method: "GET"} = conn, _params) do
    recent = Scoreboard.list_recent_runs(10)

    assigns =
      get_assigns(
        active_tab: "Event",
        course_maps: CourseMaps.list(),
        radio_frequency: Scoreboard.config(:radio_frequency),
        recent_runs: recent.completed ++ recent.running ++ recent.staged
      )

    render(conn, :event, assigns)
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
        driver_groups: group_drivers_and_runs()
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

  def collated(conn, params) do
    assigns =
      get_assigns(
        active_tab: "Collated",
        raw_scores: Scoreboard.list_raw_scores(),
        pax_scores: Scoreboard.list_pax_scores(),
        groups: Scoreboard.list_all_group_scores(),
        runs: group_drivers_and_runs(),
        cones: Scoreboard.list_total_cones(),
        print?: Map.get(params, "print")
      )

    render(conn, :collated, assigns)
  end

  defp group_drivers_and_runs() do
    Scoreboard.list_drivers_and_runs()
    |> Enum.group_by(fn entry ->
      case entry.driver_name do
        "" -> "-"
        driver_name -> driver_name |> String.at(0) |> String.upcase()
      end
    end)
  end

  defp get_assigns(extra) do
    brands = Brands.get()

    [
      root_font_size: @root_font_size,
      colors: Conecerto.Scoreboard.config(:explorer_colors),
      event_date: format_date(Scoreboard.config(:event_date)),
      event_name: Scoreboard.config(:event_name),
      last_updated_at: Scoreboard.last_updated_at(),
      organizer: brands.organizer,
      sponsors: brands.sponsors
    ]
    |> Keyword.merge(extra)
  end

  defp format_date(date) do
    date
    |> String.split("_")
    |> Enum.map(&String.to_integer(&1, 10))
    |> List.to_tuple()
    |> Date.from_erl!()
    |> Calendar.strftime("%b %d, %Y")
  end
end
