defmodule Conecerto.ScoreboardWeb.Brands do
  use GenServer

  require Logger

  @root_path "/brands"

  def root_path(), do: @root_path

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    asset_dir = Keyword.get(args, :asset_dir, Conecerto.Scoreboard.config(:brands_dir))
    GenServer.start_link(__MODULE__, [asset_dir: asset_dir], name: name)
  end

  def get(),
    do: GenServer.call(__MODULE__, :get)

  @impl true
  def init(asset_dir: nil),
    do: {:ok, %{organizer: nil, sponsors: []}}

  def init(asset_dir: asset_dir) do
    brands = list_brands(asset_dir)

    organizer = Enum.find(brands, &organizer?(&1.name))
    sponsors = Enum.reject(brands, &organizer?(&1.name))

    {:ok, %{organizer: organizer, sponsors: sponsors}}
  end

  @impl true
  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  defp list_brands(asset_dir) do
    urls = read_urls(Path.join(asset_dir, "urls.csv"))

    case File.ls(asset_dir) do
      {:ok, names} ->
        names
        |> Enum.sort()
        |> Enum.map(fn name ->
          path = Path.join(asset_dir, name)

          case file_hash(path) do
            {:ok, hash} ->
              %{
                name: name,
                path: Path.join(@root_path, "#{name}?v=#{hash}"),
                url: urls[Path.rootname(name)]
              }

            _ ->
              Logger.error("Could not hash #{path}; skipping")
              nil
          end
        end)
        |> Enum.filter(&(&1 != nil and image?(&1.name)))

      {:error, :enoent} ->
        Logger.error("Brands directory #{asset_dir} does not exist")
        []

      {:error, error} ->
        Logger.error("Could not list brands directory #{asset_dir} contents - #{inspect(error)}")
        []
    end
  end

  defp read_urls(path) do
    if File.exists?(path) do
      try do
        path
        |> File.stream!()
        |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
        |> Enum.reduce(%{}, &parse_url_row/2)
      rescue
        err in File.Error ->
          Logger.warning("Could not read brand URLs - #{inspect(err)}")
          %{}
      end
    else
      %{}
    end
  end

  defp parse_url_row(%{"name" => name, "url" => url}, urls) do
    Map.put(urls, name, url)
  end

  defp parse_url_row(row, urls) do
    Logger.warning("Could not read brand URL entry - #{inspect(row)}")
    urls
  end

  defp organizer?(name),
    do: Path.rootname(name) == "organizer"

  defp image?(name),
    do: Path.extname(name) in [".jpg", ".png"]

  defp file_hash(path) do
    with {:ok, content} <- File.read(path) do
      {:ok, :crypto.hash(:md5, content) |> Base.encode16() |> String.downcase()}
    end
  end
end
