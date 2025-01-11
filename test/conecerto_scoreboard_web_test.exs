defmodule Conecerto.ScoreboardWebTest do
  use ExUnit.Case

  defmodule TestModule do
    use Conecerto.ScoreboardWeb, :html
  end

  test "with_base_path handles non-empty base path" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.assign(:base_path, "/bar")

    assert TestModule.with_base_path(conn, "/foo") == "/bar/foo"
  end

  test "with_base_path handles nil base path" do
    conn = Phoenix.ConnTest.build_conn()

    assert TestModule.with_base_path(conn, "/foo") == "/foo"
  end

  test "with_base_path handles / base path" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.assign(:base_path, "/")

    assert TestModule.with_base_path(conn, "/foo") == "/foo"
  end
end
