defmodule Conecerto.Scoreboard.MJ.Watcher do
  use GenServer

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.MJ

  def start_link(_args) do
    event_date = Scoreboard.config(:event_date) || today_str()
    mj_dir = Scoreboard.config(:mj_dir)

    GenServer.start_link(__MODULE__, [mj_dir, event_date])
  end

  def init([mj_dir, event_date]) do
    {:ok, mj_config} = MJ.Config.read(mj_dir, event_date)

    {:ok, watcher_pid} =
      FileSystem.start_link(
        dirs: [
          mj_config.class_data_path,
          mj_config.event_data_path
        ]
      )

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
    # TODO load only data that's changed?
    classes = MJ.Classes.read(mj_config.class_data_path)
    drivers = MJ.Drivers.read(mj_config.event_driver_data_path)
    runs = MJ.Runs.read_last_day(mj_config.event_run_data_path)

    Scoreboard.load_data(classes, drivers, runs)

    Phoenix.PubSub.broadcast(Conecerto.Scoreboard.PubSub, "mj", :mj_update)
    {:noreply, %{state | timer: nil}}
  end

  defp schedule_load() do
    # TODO pass config through init
    Process.send_after(self(), :load, Scoreboard.config(:mj_debounce_interval))
  end

  defp today_str() do
    now = NaiveDateTime.local_now()
    "#{now.year}_#{pad_date_zero(now.month)}_#{pad_date_zero(now.day)}"
  end

  defp pad_date_zero(d) do
    d |> Integer.to_string() |> String.pad_leading(2, "0")
  end
end
