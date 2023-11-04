defmodule Conecerto.ScoreboardWeb.Brands do
  use GenServer

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
    {timestamp, _usecs} = NaiveDateTime.utc_now() |> NaiveDateTime.to_gregorian_seconds()

    {organizer, sponsors} =
      case File.ls(asset_dir) do
        {:ok, names} ->
          {find_organizer(names, asset_dir, timestamp),
           find_sponsors(names, asset_dir, timestamp)}

        {:error, :enoent} ->
          raise File.Error, "Branding asset directory #{asset_dir} does not exist"
      end

    {:ok, %{organizer: organizer, sponsors: sponsors}}
  end

  @impl true
  def handle_call(:get_organizer, _from, state),
    do: {:reply, state.organizer, state}

  @impl true
  def handle_call(:get_sponsors, _from, state),
    do: {:reply, state.sponsors, state}

  @impl true
  def handle_call(:any?, _from, state),
    do: {:reply, state.organizer != nil || Enum.count(state.sponsors) > 0, state}

  defp find_organizer(names, asset_dir, timestamp) do
    names
    |> Enum.find(&(image?(&1) and organizer?(&1)))
    |> make_entry(asset_dir, timestamp)
  end

  defp find_sponsors(names, asset_dir, timestamp) do
    names
    |> Enum.filter(&(image?(&1) and not organizer?(&1)))
    |> Enum.sort()
    |> Enum.map(&make_entry(&1, asset_dir, timestamp))
  end

  defp make_entry(nil = _logo_filename, _asset_dir, _timestamp),
    do: nil

  defp make_entry(logo_filename, asset_dir, timestamp),
    do: %{
      url: "/brands/#{logo_filename}?v=#{timestamp}",
      path: Path.join(asset_dir, logo_filename)
    }

  defp organizer?(path),
    do: Path.rootname(path) == "organizer"

  defp image?(path) do
    ext = Path.extname(path)
    ext == ".png" or ext == ".jpg"
  end
end
