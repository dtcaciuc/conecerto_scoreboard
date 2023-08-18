defmodule Conecerto.ScoreboardWeb.ErrorJSONTest do
  use Conecerto.ScoreboardWeb.ConnCase, async: true

  test "renders 404" do
    assert Conecerto.ScoreboardWeb.ErrorJSON.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert Conecerto.ScoreboardWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
