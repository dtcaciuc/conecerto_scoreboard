defmodule Conecerto.ScoreboardWeb.CourseMaps do
  use Conecerto.ScoreboardWeb.DynamicAssets

  require Logger

  def start_link(args) do
    name = Keyword.get(args, :name, __MODULE__)
    dir = Keyword.get(args, :dir, Conecerto.Scoreboard.config(:course_maps_dir))
    load_delay = Keyword.get(args, :load_delay, 500)
    GenServer.start_link(__MODULE__, %{dir: dir, load_delay: load_delay}, name: name)
  end

  def list(),
    do: GenServer.call(__MODULE__, :list)

  @impl Conecerto.ScoreboardWeb.DynamicAssets
  def root_path(), do: "/maps"

  @impl Conecerto.ScoreboardWeb.DynamicAssets
  def init_dynamic_assets(_args),
    do: {:ok, %{maps: []}}

  @impl Conecerto.ScoreboardWeb.DynamicAssets
  def assign_dynamic_assets(assets, state) do
    maps = assets |> Enum.filter(&image?(&1.name))
    # No need to broadcast, there's no live view displaying maps
    %{state | maps: maps}
  end

  @impl GenServer
  def handle_call(:list, _from, state) do
    {:reply, state.maps, state}
  end

  defp image?(name),
    do: Path.extname(name) in [".jpg", ".png", ".pdf"]
end
