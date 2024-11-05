defmodule Conecerto.ScoreboardWeb.PageControllerTest do
  use Conecerto.ScoreboardWeb.ConnCase

  test "GET /event", %{conn: conn} do
    conn = get(conn, ~p"/event")
    assert html_response(conn, 200) =~ "Most Recent Runs"
  end
end
