defmodule Conecerto.Scoreboard.RunsTest do
  use Conecerto.Scoreboard.DataCase

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.MJ

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoreboard.Repo)
    mj_root = Path.join([__DIR__, "data", "mj_2"])

    classes =
      Path.join([mj_root, "config", "_classData.csv"])
      |> MJ.Classes.read()

    drivers =
      Path.join([mj_root, "eventdata", "2023_07_16_driverData.csv"])
      |> MJ.Drivers.read()

    runs =
      Path.join([mj_root, "eventdata", "2023_07_16_timingData.csv"])
      |> MJ.Runs.read_last_day()

    Scoreboard.load_data(classes, drivers, runs)

    :ok
  end

  test "list_drivers_and_runs" do
    assert drivers = Scoreboard.list_drivers_and_runs()
    assert 88 = Enum.count(drivers)

    for d <- drivers do
      assert Enum.count(d.runs) > 0
    end

    [d0 | _rest] = drivers

    assert %{driver_name: "Allen, Jess", runs: runs} = d0
    assert 6 = Enum.count(runs)

    assert [
             %{penalty: "2", run_time: 42.785, counted_run_no: 1, selected: false},
             %{penalty: "", run_time: 42.84, counted_run_no: 2, selected: false},
             %{penalty: "1", run_time: 42.501, counted_run_no: 3, selected: false},
             %{penalty: "", run_time: 42.271, counted_run_no: 4, selected: true},
             %{penalty: "", run_time: 42.661, counted_run_no: 5, selected: false},
             %{penalty: "2", run_time: 42.161, counted_run_no: 6, selected: false}
           ] =
             runs
             |> Enum.map(
               &%{
                 counted_run_no: &1.counted_run_no,
                 run_time: &1.run_time,
                 penalty: &1.penalty,
                 selected: &1.selected
               }
             )
  end
end
