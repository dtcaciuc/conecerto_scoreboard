defmodule Conecerto.ScoreboardWeb.Router do
  use Conecerto.ScoreboardWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {Conecerto.ScoreboardWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Conecerto.ScoreboardWeb do
    pipe_through :browser

    head "/", ScoresController, :home
    get "/", ScoresController, :home
    get "/raw", ScoresController, :raw
    get "/pax", ScoresController, :pax
    get "/groups", ScoresController, :groups
    get "/runs", ScoresController, :runs

    live "/announce", Announce
    live "/tv", Tv
  end

  # Other scopes may use custom stacks.
  # scope "/api", Conecerto.ScoreboardWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:conecerto_scoreboard, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Conecerto.ScoreboardWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
