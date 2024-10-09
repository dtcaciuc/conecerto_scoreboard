defmodule Conecerto.ScoreboardWeb.Brands do
  use GenServer

  require Logger

  @endpoint Conecerto.ScoreboardWeb.Endpoint

  def start_link(args) do
    {name, args} = Keyword.pop(args, :name, __MODULE__)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def get_organizer(),
    do: GenServer.call(__MODULE__, :get_organizer)

  def get_sponsors(),
    do: GenServer.call(__MODULE__, :get_sponsors)

  def any?(),
    do: GenServer.call(__MODULE__, :any?)

  @impl true
  def init(asset_dir: nil),
    do: {:ok, %{organizer: nil, sponsors: []}}

  def init(asset_dir: asset_dir) do
    files = list_images(asset_dir)

    organizer = Enum.find(files, &organizer?(&1.name))
    sponsors = Enum.reject(files, &organizer?(&1.name))

    {:ok, %{organizer: organizer, sponsors: sponsors}}
  end

  @impl true
  def handle_call(:get_organizer, _from, state),
    do: {:reply, put_url(state.organizer), state}

  @impl true
  def handle_call(:get_sponsors, _from, state),
    do: {:reply, Enum.map(state.sponsors, &put_url/1), state}

  @impl true
  def handle_call(:any?, _from, state),
    do: {:reply, state.organizer != nil || Enum.count(state.sponsors) > 0, state}

  defp list_images(asset_dir) do
    case File.ls(asset_dir) do
      {:ok, names} ->
        names
        |> Enum.sort()
        |> Enum.map(fn name ->
          path = Path.join(asset_dir, name)

          case file_hash(path) do
            {:ok, hash} ->
              %{name: name, path: path, hash: hash}

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

  # Adding URL dynamically since we start up before the endpoint does.
  defp put_url(nil),
    do: nil

  defp put_url(entry),
    do: Map.put(entry, :url, @endpoint.path("/brands/#{entry.name}?v=#{entry.hash}"))

  defp organizer?(path),
    do: Path.rootname(path) == "organizer"

  defp image?(path) do
    ext = Path.extname(path)
    ext == ".png" or ext == ".jpg"
  end

  defp file_hash(path) do
    with {:ok, content} <- File.read(path) do
      {:ok, :crypto.hash(:md5, content) |> Base.encode16() |> String.downcase()}
    end
  end
end
