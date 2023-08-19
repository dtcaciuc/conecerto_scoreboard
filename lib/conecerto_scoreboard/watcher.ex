defmodule Conecerto.Scoreboard.Watcher do
  use GenServer

  alias Conecerto.Scoreboard

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init([mj_dir, event_date]) do
    {:ok, mj_config} = Conecerto.Scoreboard.MJ.Config.read(mj_dir, event_date)
    {:ok, watcher_pid} = FileSystem.start_link(dirs: [mj_config.root_path])
    FileSystem.subscribe(watcher_pid)

    {:ok, %{mj_config: mj_config, timer: schedule_load()}}
  end

  def handle_info(
        {:file_event, _watcher_pid, {path, _events}},
        %{mj_config: mj_config, timer: timer} = state
      ) do
    timer =
      if path == mj_config.class_data_path or
           path == mj_config.event_run_data_path or
           path == mj_config.event_driver_data_path do
        if timer != nil do
          Process.cancel_timer(timer)
        end

        schedule_load()
      else
        timer
      end

    {:noreply, %{state | timer: timer}}
  end

  def handle_info(:load, %{mj_config: mj_config} = state) do
    Conecerto.Scoreboard.load_data(mj_config)
    Phoenix.PubSub.broadcast(Conecerto.Scoreboard.PubSub, "mj", :mj_update)
    {:noreply, %{state | timer: nil}}
  end

  defp schedule_load() do
    Process.send_after(self(), :load, Scoreboard.config(:mj_debounce_interval))
  end
end
