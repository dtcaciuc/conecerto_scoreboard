defmodule Conecerto.Scoreboard.Uploader do
  use GenServer

  require Phoenix.ConnTest
  require Logger

  alias Conecerto.Scoreboard

  @endpoint Conecerto.ScoreboardWeb.Endpoint

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(_) do
    if Scoreboard.config(:live_ftp_host) == nil do
      Logger.warning("live ftp server is not configured")
      :ignore
    else
      :ok = Phoenix.PubSub.subscribe(Conecerto.Scoreboard.PubSub, "mj")
      {:ok, %{}, {:continue, :upload_assets}}
    end
  end

  @impl true
  def handle_continue(:upload_assets, state) do
    with {:ok, pid} <- connect(),
         :ok = :ftp.type(pid, :binary),
         :ok <- send_static(pid, "/favicon.ico", true),
         :ftp.mkdir(pid, "assets" |> String.to_charlist()),
         :ok <- send_static(pid, "/assets/app.css"),
         :ok <- send_static(pid, "/assets/app.js"),
         :ftp.mkdir(pid, "fonts" |> String.to_charlist()),
         :ok <- send_static(pid, "/fonts/RobotoCondensed-Regular.ttf"),
         :ftp.close(pid) do
      Logger.info("results assets uploaded")
    else
      {:error, reason} when is_binary(reason) ->
        Logger.error("could not upload results; #{reason}")

      other ->
        Logger.error("could not upload results assets; #{inspect(other)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:mj_update, state) do
    t0 = :os.system_time(:millisecond)

    with {:ok, pid} <- connect(),
         :ok <- :ftp.type(pid, :binary),
         :ok <- send_page(pid, "", "index"),
         :ok <- send_page(pid, "raw"),
         :ok <- send_page(pid, "pax"),
         :ok <- send_page(pid, "groups"),
         :ok <- send_page(pid, "runs"),
         :ok <- :ftp.close(pid) do
      t1 = :os.system_time(:millisecond)
      Logger.info("live results uploaded in #{t1 - t0}ms")
    else
      {:error, reason} when is_binary(reason) ->
        Logger.error("could not upload results; #{reason}")

      _ ->
        Logger.error("could not upload results")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp connect() do
    with {:ok, pid} <- :ftp.open(Scoreboard.config(:live_ftp_host) |> String.to_charlist()),
         :ok <-
           :ftp.user(
             pid,
             Scoreboard.config(:live_ftp_user) |> String.to_charlist(),
             Scoreboard.config(:live_ftp_pass) |> String.to_charlist()
           ) do
      {:ok, pid}
    else
      {:error, :ehost} ->
        {:error, "results host is unreachable"}

      {:error, :euser} ->
        {:error, "wrong results host username or password"}
    end
  end

  defp send_page(ftp_pid, url, filename \\ nil) do
    filename = filename || url
    Logger.debug("Uploading #{url} -> #{filename}")

    with conn <- Phoenix.ConnTest.build_conn(),
         %{status: 200, resp_body: body} <- Phoenix.ConnTest.get(conn, "/#{url}"),
         :ok <- :ftp.send_bin(ftp_pid, :zlib.gzip(body), "#{filename}.gz" |> String.to_charlist()) do
      :ok
    else
      %Plug.Conn{status: status} ->
        {:error, "could generate results page; request returned status #{status}"}
    end
  end

  defp send_static(ftp_pid, path, raw \\ false) do
    static_path =
      if raw do
        path
      else
        String.split(@endpoint.static_path(path), "?") |> hd()
      end

    abs_path = Path.join(static_dir(), static_path)
    Logger.debug("Uploading #{abs_path} > #{static_path}")
    :ftp.send(ftp_pid, abs_path |> String.to_charlist(), static_path |> String.to_charlist())
  end

  defp static_dir() do
    Application.app_dir(:conecerto_scoreboard, ["priv", "static"])
  end
end
