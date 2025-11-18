defmodule Conecerto.ScoreboardWeb.Brands do
  use Conecerto.ScoreboardWeb.DynamicAssets

  require Logger

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    dir = Keyword.get(args, :dir, Conecerto.Scoreboard.config(:brands_dir))
    load_delay = Keyword.get(args, :load_delay, 500)
    GenServer.start_link(__MODULE__, %{dir: dir, load_delay: load_delay}, name: name)
  end

  def get(),
    do: GenServer.call(__MODULE__, :get)

  def list() do
    brands = get()

    case brands.organizer do
      nil ->
        brands.sponsors

      organizer ->
        [organizer | brands.sponsors]
    end
  end

  @impl GenServer
  def handle_call(:get, _from, state) do
    {:reply, state.brands, state}
  end

  @impl Conecerto.ScoreboardWeb.DynamicAssets
  def root_path(), do: "/brands"

  @impl Conecerto.ScoreboardWeb.DynamicAssets
  def init_dynamic_assets(_args),
    do: {:ok, %{brands: %{organizer: nil, sponsors: []}}}

  @impl Conecerto.ScoreboardWeb.DynamicAssets
  def assign_dynamic_assets(assets, state) do
    urls = read_urls(Path.join(state.dir, "urls.csv"))

    brands_list =
      assets
      |> Enum.map(&Map.put(&1, :url, urls[Path.rootname(&1.name)]))
      |> Enum.filter(&image?(&1.name))

    organizer = Enum.find(brands_list, &organizer?(&1.name))
    sponsors = Enum.reject(brands_list, &organizer?(&1.name))

    brands = %{organizer: organizer, sponsors: sponsors}
    Phoenix.PubSub.broadcast(Conecerto.Scoreboard.PubSub, "assets", {:brands_updated, brands})

    %{state | brands: brands}
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
end
