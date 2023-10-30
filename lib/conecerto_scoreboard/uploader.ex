defmodule Conecerto.Scoreboard.Uploader do
  use GenServer

  require Phoenix.ConnTest
  require Logger

  alias Conecerto.Scoreboard
  alias Conecerto.ScoreboardWeb.Brands

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
         :ok <- mkdir(pid, "/"),
         :ok <- send_static(pid, "/favicon.ico"),
         :ok <- mkdir(pid, "assets"),
         :ok <- send_static(pid, "/assets/app.css"),
         :ok <- send_static(pid, "/assets/app.js"),
         :ok <- mkdir(pid, "fonts"),
         :ok <- send_static(pid, "/fonts/RobotoCondensed-Regular.ttf"),
         :ok <- mkdir(pid, "brands"),
         :ok <- send_brands(pid),
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
    filename = Path.join(Scoreboard.config(:live_ftp_path), filename || url)
    Logger.debug("Uploading #{url} -> #{filename}.gz")

    with conn <- Phoenix.ConnTest.build_conn(),
         %{status: 200, resp_body: body} <- Phoenix.ConnTest.get(conn, "/#{url}"),
         :ok <- :ftp.send_bin(ftp_pid, :zlib.gzip(body), "#{filename}.gz" |> String.to_charlist()) do
      :ok
    else
      %Plug.Conn{status: status} ->
        {:error, "could generate results page; request returned status #{status}"}
    end
  end

  defp send_static(ftp_pid, path, src_path \\ nil) do
    [static_path | _] = String.split(@endpoint.static_path(path), "?")

    dest_path = Path.join(Scoreboard.config(:live_ftp_path), static_path)

    src_path =
      if src_path == nil do
        Path.join(static_dir(), static_path)
      else
        src_path
      end

    Logger.debug("Uploading #{src_path} > #{dest_path}")
    :ftp.send(ftp_pid, src_path |> String.to_charlist(), dest_path |> String.to_charlist())
  end

  defp send_brands(ftp_pid) do
    brands = [Brands.get_organizer() | Brands.get_sponsors()]

    for b <- brands, b != nil, reduce: :ok do
      :ok ->
        send_static(ftp_pid, b.url, b.path)

      other ->
        other
    end
  end

  defp mkdir(pid, path) do
    path = Path.join(Scoreboard.config(:live_ftp_path), path)
    Logger.debug("Creating #{path}")
    # Ignore mkdir result; if directory already exists it returns an error
    :ftp.mkdir(pid, path |> String.to_charlist())
    :ok
  end

  defp static_dir() do
    Application.app_dir(:conecerto_scoreboard, ["priv", "static"])
  end
end
