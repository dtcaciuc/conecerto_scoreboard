defmodule Conecerto.Scoreboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Conecerto.Scoreboard.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:conecerto_scoreboard, :ecto_repos), skip: false},
      # Start the PubSub system
      {Phoenix.PubSub, name: Conecerto.Scoreboard.PubSub},
      # Start branding asset resource manager
      {Conecerto.ScoreboardWeb.Brands, asset_dir: Conecerto.Scoreboard.config(:brands_dir)},
      # Start the Endpoint (http/https)
      Conecerto.ScoreboardWeb.Endpoint
    ]

    children =
      children
      |> add_child_if_set(Conecerto.Scoreboard.config(:watcher))
      |> add_child_if_set(Conecerto.Scoreboard.config(:uploader))

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Conecerto.Scoreboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp add_child_if_set(children, nil), do: children
  defp add_child_if_set(children, child), do: children ++ [child]

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Conecerto.ScoreboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
