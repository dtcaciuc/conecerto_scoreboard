defmodule Conecerto.ScoreboardWeb.DynamicAssets do
  @callback root_path() :: String.t()
  @callback init_dynamic_assets(args :: map) :: any
  @callback assign_dynamic_assets(assets :: list, state :: map) :: any

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      require Logger

      @behaviour Conecerto.ScoreboardWeb.DynamicAssets

      @impl GenServer
      def init(%{dir: nil} = args),
        do: init_dynamic_assets(args)

      def init(args) do
        %{dir: dir, load_delay: load_delay} = args

        {:ok, watcher_pid} = FileSystem.start_link(dirs: [dir])
        FileSystem.subscribe(watcher_pid)

        {:ok, state} = init_dynamic_assets(args)

        state =
          state
          |> Map.put(:dir, dir)
          |> Map.put(:load_delay, load_delay)
          |> Map.put(:load_timer, schedule_load(0))

        {:ok, state}
      end

      @impl true
      def handle_info({:file_event, _watcher_pid, {_path, _events}}, state) do
        %{load_timer: timer, load_delay: delay} = state

        if timer != nil do
          Process.cancel_timer(timer)
        end

        {:noreply, %{state | load_timer: schedule_load(delay)}}
      end

      def handle_info(:load_assets, state) do
        %{dir: dir} = state

        assets =
          case File.ls(dir) do
            {:ok, names} ->
              read_files(dir, names)

            {:error, :enoent} ->
              Logger.error("Asset directory #{dir} does not exist")
              []

            {:error, error} ->
              Logger.error("Could not list asset directory #{dir} contents - #{inspect(error)}")
              []
          end

        {:noreply, assign_dynamic_assets(assets, state)}
      end

      defp read_files(dir, names) do
        names
        |> Enum.sort()
        |> Enum.map(fn name ->
          path = Path.join(dir, name)

          with {:dir, false} <- {:dir, File.dir?(path)},
               {:ok, hash} <- file_hash(path) do
            %{
              name: name,
              path: Path.join(root_path(), "#{name}?v=#{hash}")
            }
          else
            {:dir, true} ->
              nil

            {:error, reason} ->
              Logger.error("Could not hash #{path}; skipping")
              nil
          end
        end)
        |> Enum.reject(&is_nil(&1))
      end

      defp file_hash(path) do
        with {:ok, content} <- File.read(path) do
          {:ok, :crypto.hash(:md5, content) |> Base.encode16() |> String.downcase()}
        end
      end

      defp schedule_load(delay) do
        Process.send_after(self(), :load_assets, delay)
      end
    end
  end
end
