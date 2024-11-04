defmodule Conecerto.Scoreboard.Uploader do
  use GenServer

  require Phoenix.ConnTest
  require Logger

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.FTP
  alias Conecerto.ScoreboardWeb.Brands

  @endpoint Conecerto.ScoreboardWeb.Endpoint

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
         :ok <- send_page(client, base_path, "/", "index"),
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

  defp send_page(client, base_path, path, new_name \\ nil) do
    filename = new_name || path

    with conn <- Phoenix.ConnTest.build_conn(),
         conn <- Plug.Conn.assign(conn, :base_path, base_path),
         %{status: 200, resp_body: body} <- Phoenix.ConnTest.get(conn, path) do
      FTP.send_bin(client, :zlib.gzip(body), "#{filename}.gz")
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
