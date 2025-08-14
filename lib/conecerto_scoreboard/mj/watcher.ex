defmodule Conecerto.Scoreboard.MJ.Watcher do
  use GenServer

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.MJ

  require Logger

  def start_link(_) do
    args = Application.fetch_env!(:conecerto_scoreboard, __MODULE__)
    {mj_dir, args} = Keyword.pop(args, :mj_dir)

    {:ok, mj_config} = MJ.Config.read(mj_dir, Scoreboard.config(:event_date))

    args =
      args
      |> Keyword.put(:mj_config, mj_config)
      |> Keyword.put(:group_by_class?, Scoreboard.config(:group_by_class?))

    GenServer.start_link(__MODULE__, Map.new(args))
  end

  def init(args) do
    %{
      mj_config: mj_config,
      poll_changes?: poll_changes?,
      poll_interval: poll_interval,
      debounce_interval: load_delay,
      group_by_class?: group_by_class?
    } = args

    dir_args = [dirs: [Path.dirname(mj_config.class_data_path), mj_config.event_data_path]]

    backend_args =
      if poll_changes? do
        Logger.info("Watcher will poll files for changes every #{poll_interval}ms")
        [backend: :fs_poll, interval: poll_interval]
      else
        []
      end

    {:ok, watcher_pid} = FileSystem.start_link(dir_args ++ backend_args)
    FileSystem.subscribe(watcher_pid)

    {:ok,
     %{
       mj_config: mj_config,
       load_delay: load_delay,
       timer: schedule_load(load_delay),
       group_by_class?: group_by_class?
     }}
  end

  def handle_info({:file_event, _watcher_pid, {path, _events}}, state) do
    %{mj_config: mj_config, load_delay: load_delay, timer: timer} = state

    timer =
      if path == mj_config.class_data_path or
           path == mj_config.event_run_data_path or
           path == mj_config.event_driver_data_path do
        if timer != nil do
          Process.cancel_timer(timer)
        end

        schedule_load(load_delay)
      else
        timer
      end

    {:noreply, %{state | timer: timer}}
  end

  def handle_info(:load, state) do
    %{mj_config: mj_config, group_by_class?: group_by_class?} = state

    # TODO load only data that's changed?
    classes = MJ.Classes.read(mj_config.class_data_path)
    drivers = MJ.Drivers.read(mj_config.event_driver_data_path, group_by_class?: group_by_class?)
    runs = MJ.Runs.read_last_day(mj_config.event_run_data_path)

    Scoreboard.load_data(classes, drivers, runs)

    Phoenix.PubSub.broadcast(Conecerto.Scoreboard.PubSub, "mj", :mj_update)
    {:noreply, %{state | timer: nil}}
  end

  defp schedule_load(delay) do
    Process.send_after(self(), :load, delay)
  end
end
