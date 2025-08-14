defmodule Conecerto.Scoreboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @repos Application.compile_env!(:conecerto_scoreboard, :ecto_repos)
  @watcher Application.compile_env!(:conecerto_scoreboard, :watcher)
  @uploader Application.compile_env!(:conecerto_scoreboard, :uploader)

  @impl true
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: Conecerto.Scoreboard.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Conecerto.ScoreboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def children() do
    [
      Conecerto.Scoreboard.Repo,
      with_id({Phoenix.PubSub, name: Conecerto.Scoreboard.PubSub}, Conecerto.Scoreboard.PubSub),
      with_id({Ecto.Migrator, repos: @repos, skip: false}, id: Conecerto.Scoreboard.Migrator),
      # Branding asset resource manager
      Conecerto.ScoreboardWeb.Brands,
      # Start the Endpoint (http/https)
      Conecerto.ScoreboardWeb.Endpoint,
      @watcher,
      @uploader
    ]
    |> Enum.filter(&(&1 != nil))
  end

  defp with_id(spec, id),
    do: Supervisor.child_spec(spec, id: id)
end
