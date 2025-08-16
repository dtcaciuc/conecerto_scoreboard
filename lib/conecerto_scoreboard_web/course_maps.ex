defmodule Conecerto.ScoreboardWeb.CourseMaps do
  use GenServer

  require Logger

  @root_path "/maps"

  def root_path(),
    do: @root_path

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    dir = Keyword.get(args, :dir, Conecerto.Scoreboard.config(:course_maps_dir))
    GenServer.start_link(__MODULE__, dir, name: name)
  end

  def list(),
    do: GenServer.call(__MODULE__, :list)

  @impl GenServer
  def init(nil),
    do: {:ok, %{maps: []}}

  def init(dir) do
    maps =
      case File.ls(dir) do
        {:ok, names} ->
          names
          |> Enum.sort()
          |> Enum.map(fn name ->
            path = Path.join(dir, name)

            case file_hash(path) do
              {:ok, hash} ->
                %{
                  name: name,
                  path: Path.join(@root_path, "#{name}?v=#{hash}")
                }

              _ ->
                Logger.error("Could not hash #{path}; skipping")
                nil
            end
          end)
          |> Enum.filter(&(&1 != nil and image?(&1.name)))

        {:error, :enoent} ->
          Logger.error("Course maps directory #{dir} does not exist")
          []

        {:error, error} ->
          Logger.error("Could not list course maps directory #{dir} contents - #{inspect(error)}")
          []
      end

    {:ok, %{maps: maps}}
  end

  @impl GenServer
  def handle_call(:list, _from, state) do
    {:reply, state.maps, state}
  end

  defp image?(name),
    do: Path.extname(name) in [".jpg", ".png", ".pdf"]

  defp file_hash(path) do
    with {:ok, content} <- File.read(path) do
      {:ok, :crypto.hash(:md5, content) |> Base.encode16() |> String.downcase()}
    end
  end
end
