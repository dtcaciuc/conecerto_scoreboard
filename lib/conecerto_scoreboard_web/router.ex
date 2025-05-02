defmodule Conecerto.ScoreboardWeb.Router do
  use Conecerto.ScoreboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Conecerto.ScoreboardWeb.Layouts, :root}
    plug :put_default_colors
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", Conecerto.ScoreboardWeb do
    pipe_through :browser

    head "/", ExplorerController, :index
    get "/", ExplorerController, :index

    get "/event", ExplorerController, :event
    get "/raw", ExplorerController, :raw
    get "/pax", ExplorerController, :pax
    get "/groups", ExplorerController, :groups
    get "/runs", ExplorerController, :runs
    get "/cones", ExplorerController, :cones

    live "/announce", Announce
    live "/tv", Tv
  end

  defp put_default_colors(conn, _opts) do
    assign(conn, :colors, Conecerto.ScoreboardWeb.Colors.default_colors())
  end
end
