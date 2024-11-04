defmodule Conecerto.Scoreboard.Uploader do
  use GenServer

  require Phoenix.ConnTest
  require Logger

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.FTP
  alias Conecerto.ScoreboardWeb.Brands

  @endpoint Conecerto.ScoreboardWeb.Endpoint

  @htaccess ~s(
RewriteEngine On

# Index redirects to event page
RewriteRule "^$" event [R=302,L]

# Deny Phoenix live reload stuff that doesn't exist
RewriteRule "^phoenix/live_reload/frame$" event [R=404,L]

# Serve gzip compressed files.
RewriteCond "%{HTTP:Accept-Encoding}" "gzip"
RewriteCond "%{REQUEST_FILENAME}\.html.gz" -s
RewriteRule "^\(.*\)" "$1\.html.gz" [QSA]

# Serve correct content types, and prevent mod_deflate double gzip.
RewriteRule "\.html.gz$" "-" [T=text/html,E=no-gzip:1]

<FilesMatch "\(\.gz\)$">
  Header set Content-Encoding gzip
  Header append Vary Accept-Encoding
</FilesMatch>

# Redirect non-existent pages
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ".*" event [R=302,L]
)

  def start_link(_) do
    args = %{
      client_args: Scoreboard.config(:explorer_remote_ftp),
      base_path: Scoreboard.config(:explorer_remote_http_base_path)
    }

    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init(args) do
    if Keyword.get(args.client_args, :host) == nil do
      Logger.warning("FTP server is not configured")
      :ignore
    else
      :ok = Phoenix.PubSub.subscribe(Conecerto.Scoreboard.PubSub, "mj")
      {:ok, args, {:continue, :upload_assets}}
    end
  end

  @impl true
  def handle_continue(:upload_assets, state) do
    with {:ok, client} <- FTP.open(state.client_args),
         :ok <- FTP.mkdir(client, "/"),
         :ok <- FTP.send_bin(client, @htaccess, "/.htaccess"),
         :ok <- send_static(client, "/favicon.ico"),
         :ok <- FTP.mkdir(client, "assets"),
         :ok <- send_static(client, "/assets/app.css"),
         :ok <- send_static(client, "/assets/app.js"),
         :ok <- FTP.mkdir(client, "fonts"),
         :ok <- send_static(client, "/fonts/RobotoCondensed-Regular.ttf"),
         :ok <- FTP.mkdir(client, "brands"),
         :ok <- send_brands(client),
         FTP.close(client) do
      Logger.info("Assets uploaded")
    else
      {:error, reason} when is_binary(reason) ->
        Logger.error("Could not upload assets - #{reason}")

      other ->
        Logger.error("Could not upload assets - #{inspect(other)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:mj_update, state) do
    base_path = state.base_path
    t0 = :os.system_time(:millisecond)

    with {:ok, client} <- FTP.open(state.client_args),
         :ok <- send_page(client, base_path, "/event"),
         :ok <- send_page(client, base_path, "/raw"),
         :ok <- send_page(client, base_path, "/pax"),
         :ok <- send_page(client, base_path, "/groups"),
         :ok <- send_page(client, base_path, "/runs"),
         :ok <- FTP.close(client) do
      t1 = :os.system_time(:millisecond)
      Logger.info("Results uploaded in #{t1 - t0}ms")
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

  defp send_page(client, base_path, path) do
    with conn <- Phoenix.ConnTest.build_conn(),
         conn <- Plug.Conn.assign(conn, :base_path, base_path),
         %{status: 200, resp_body: body} <- Phoenix.ConnTest.get(conn, path) do
      FTP.send_bin(client, :zlib.gzip(body), "#{path}.html.gz")
    else
      %Plug.Conn{status: status} ->
        {:error, "Could generate results page - request returned HTTP #{status}"}
    end
  end

  defp send_static(client, path) do
    [static_path | _] = String.split(@endpoint.static_path(path), "?")

    with conn <- Phoenix.ConnTest.build_conn(),
         %{status: 200, resp_body: body} <- Phoenix.ConnTest.get(conn, path) do
      FTP.send_bin(client, body, static_path)
    else
      %Plug.Conn{status: status} ->
        {:error, "Could not generate static file - request returned HTTP #{status}"}
    end
  end

  defp send_brands(ftp_pid) do
    brands = [Brands.get_organizer() | Brands.get_sponsors()]

    for b <- brands, b != nil, reduce: :ok do
      :ok ->
        send_static(ftp_pid, @endpoint.path(b.path))

      other ->
        other
    end
  end
end
