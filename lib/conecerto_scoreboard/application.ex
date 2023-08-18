defmodule Conecerto.Scoreboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp today_str() do
    now = NaiveDateTime.local_now()
    pad_zero = fn d -> d |> Integer.to_string() |> String.pad_leading(2, "0") end
    "#{now.year}_#{pad_zero.(now.month)}_#{pad_zero.(now.day)}"
  end

  @impl true
  def start(_type, _args) do
    event_date = Conecerto.Scoreboard.config(:event_date) || today_str()
    mj_dir = Conecerto.Scoreboard.config(:mj_dir)

    children = [
      # Start the Telemetry supervisor
      Conecerto.ScoreboardWeb.Telemetry,
      # Start the Ecto repository
      Conecerto.Scoreboard.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Conecerto.Scoreboard.PubSub},
      # Start Finch
      # {Finch, name: Conecerto.Scoreboard.Finch},
      # Start the Endpoint (http/https)
      Conecerto.ScoreboardWeb.Endpoint
    ]

    children =
      if System.get_env("DISABLE_WATCHER") == nil do
        children ++
          [
            {Conecerto.Scoreboard.Watcher, [mj_dir, event_date]}
          ]
      else
        children
      end

    children =
      if System.get_env("DISABLE_UPLOADER") == nil do
        children ++
          [
            Conecerto.Scoreboard.Uploader
          ]
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Conecerto.Scoreboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Conecerto.ScoreboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
