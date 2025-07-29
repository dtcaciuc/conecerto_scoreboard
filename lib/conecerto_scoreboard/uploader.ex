defmodule Conecerto.Scoreboard.Uploader do
  use GenServer

  require Phoenix.ConnTest
  require Logger

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.FTP
  alias Conecerto.ScoreboardWeb.Brands

  @endpoint Conecerto.ScoreboardWeb.Endpoint
  @pubsub_server Conecerto.Scoreboard.PubSub

  @htaccess_template ~s(
RewriteEngine On

RewriteBase <%= base_path %>

# Index redirects to event page
RewriteRule "^$" <%= default_page %> [R=302,L]

# Deny Phoenix live reload stuff that doesn't exist
RewriteRule "^phoenix/live_reload/frame$" <%= default_page %> [R=404,L]

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
)

  def start_link(_) do
    args = %{
      client_args: Scoreboard.config(:explorer_remote_ftp),
      base_path: Scoreboard.config(:explorer_remote_http_base_path),
      default_page: Scoreboard.config(:explorer_default_page)
    }

    GenServer.start_link(__MODULE__, args)
  end

  def upload_once(args) do
    with :ok <- send_assets(args),
         :ok <- send_content(args) do
      :ok
    end
  end

  @impl true
  def init(args) do
    if Keyword.get(args.client_args, :host) == nil do
      Logger.warning("FTP server is not configured")
      :ignore
    else
      :ok = Phoenix.PubSub.subscribe(@pubsub_server, "mj")
      {:ok, args, {:continue, :send_assets}}
    end
  end

  @impl true
  def handle_continue(:send_assets, state) do
    send_assets(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(:mj_update, state) do
    with :ok <- send_content(state) do
      Phoenix.PubSub.broadcast(@pubsub_server, "explorer", :uploaded)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp send_assets(state) do
    htaccess =
      EEx.eval_string(@htaccess_template,
        base_path: state.base_path,
        default_page: state.default_page
      )

    with {:ok, client} <- FTP.open(state.client_args),
         :ok <- FTP.mkdir(client, "/"),
         :ok <- FTP.send_bin(client, htaccess, "/.htaccess"),
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
      :ok
    else
      {:error, reason} when is_binary(reason) ->
        Logger.error("Could not upload assets - #{reason}")
        {:error, reason}

      other ->
        Logger.error("Could not upload assets - #{inspect(other)}")
        {:error, :unknown_reason}
    end
  end

  defp send_content(state) do
    base_path = state.base_path
    t0 = :os.system_time(:millisecond)

    with {:ok, client} <- FTP.open(state.client_args),
         :ok <- send_page(client, base_path, "/event"),
         :ok <- send_page(client, base_path, "/raw"),
         :ok <- send_page(client, base_path, "/pax"),
         :ok <- send_page(client, base_path, "/groups"),
         :ok <- send_page(client, base_path, "/runs"),
         :ok <- send_page(client, base_path, "/cones"),
         :ok <- FTP.close(client) do
      t1 = :os.system_time(:millisecond)
      Logger.info("Results uploaded in #{t1 - t0}ms")
      :ok
    else
      {:error, reason} when is_binary(reason) ->
        Logger.error("could not upload results; #{reason}")
        {:error, reason}

      _ ->
        Logger.error("could not upload results")
        {:error, :unknown_reason}
    end
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
    brands = Brands.get()

    for b <- [brands.organizer | brands.sponsors], b != nil, reduce: :ok do
      :ok ->
        send_static(ftp_pid, @endpoint.path(b.path))

      other ->
        other
    end
  end
end
