defmodule Conecerto.Scoreboard.RunsTest do
  use Conecerto.Scoreboard.DataCase

  alias Conecerto.Scoreboard
  alias Conecerto.Scoreboard.MJ

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoreboard.Repo)
    seed_test_data()
  end

  test "list_recent_runs" do
    seed_test_data([
      %{car_no: 9, run_no: 6, penalty: "", run_time: -1.0},
      %{car_no: 16, run_no: 7, penalty: "1", run_time: -1.0},
      %{car_no: 31, run_no: 7, penalty: "", run_time: nil}
    ])

    assert [
             %{
               car_class: "HS",
               car_model: "'92 Acura Integra GS",
               car_no: 10,
               counted_run_no: 6,
               driver_name: "Johnson, William",
               id: 691,
               penalty: "5",
               run_time: 50.652,
               status: "completed"
             },
             %{
               car_class: "STU",
               car_model: "'17 Volkswagen golf r",
               car_no: 32,
               counted_run_no: 6,
               driver_name: "Jackson, Miguel",
               id: 692,
               penalty: "",
               run_time: 47.164,
               status: "completed"
             },
             %{
               car_class: "STS",
               car_model: "'05 Lexus Is300",
               car_no: 9,
               counted_run_no: 6,
               driver_name: "Milewski, Dan",
               id: 1,
               penalty: "",
               run_time: nil,
               status: "running"
             },
             %{
               car_class: "SS",
               car_model: "'12 Nissan GT-R",
               car_no: 16,
               counted_run_no: 7,
               driver_name: "Leclair, Billy",
               id: 2,
               penalty: "1",
               run_time: nil,
               status: "running"
             },
             %{
               car_class: "ES",
               car_model: "'02 Mazda Miata",
               car_no: 31,
               counted_run_no: 7,
               driver_name: "Michelle, Gary",
               id: 3,
               penalty: "",
               run_time: nil,
               status: "queued"
             }
           ] = Scoreboard.list_recent_runs(5)
  end

  test "list_drivers_and_runs" do
    assert drivers = Scoreboard.list_drivers_and_runs()
    assert 56 == Enum.count(drivers)

    for d <- drivers do
      assert Enum.count(d.runs) > 0
    end

    assert {d, 0} =
             drivers
             |> Enum.with_index()
             |> Enum.find(fn {d, _} -> d.car_no == 27 end)

    assert %{driver_name: "Allen, Jess", runs: runs} = d

    assert [
             %{penalty: "2", run_time: 42.785, counted_run_no: 1, best: false},
             %{penalty: "", run_time: 42.84, counted_run_no: 2, best: false},
             %{penalty: "1", run_time: 42.501, counted_run_no: 3, best: false},
             %{penalty: "", run_time: 42.271, counted_run_no: 4, best: true},
             %{penalty: "", run_time: 42.661, counted_run_no: 5, best: false},
             %{penalty: "2", run_time: 42.161, counted_run_no: 6, best: false}
           ] =
             runs
             |> Enum.map(
               &%{
                 counted_run_no: &1.counted_run_no,
                 run_time: &1.run_time,
                 penalty: &1.penalty,
                 best: &1.best
               }
             )
  end

  test "list_drivers_and_runs - Reruns are excluded" do
    assert drivers = Scoreboard.list_drivers_and_runs()

    # Rerun is the fastest time but its excluded
    assert {d, 22} =
             drivers
             |> Enum.with_index()
             |> Enum.find(fn {d, _} -> d.car_no == 35 end)

    assert %{driver_name: "Hossack, Richard", runs: runs} = d
    assert %{penalty: "RRN", best: false} = runs |> Enum.min_by(& &1.run_time)
  end

  test "list_drivers_and_runs - Zero run times are intepreted as max time" do
    assert drivers = Scoreboard.list_drivers_and_runs()

    assert {d, 17} =
             drivers
             |> Enum.with_index()
             |> Enum.find(fn {d, _} -> d.car_no == 11 end)

    assert %{driver_name: "Gonzalez, Megan", runs: runs} = d

    assert [
             %{best: false, counted_run_no: 1, id: 45, penalty: "3", run_time: 51.433},
             %{best: false, counted_run_no: 2, id: 69, penalty: "", run_time: 49.254},
             %{best: false, counted_run_no: 3, id: 93, penalty: "", run_time: 47.816},
             %{best: false, counted_run_no: nil, id: 219, penalty: "RRN", run_time: 999.999},
             %{best: false, counted_run_no: 4, id: 241, penalty: "", run_time: 48.6},
             %{best: false, counted_run_no: 5, id: 267, penalty: "", run_time: 48.458},
             %{best: true, counted_run_no: 6, id: 293, penalty: "", run_time: 47.811}
           ] = runs
  end

  def seed_test_data(extra_runs \\ []) do
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

    Scoreboard.load_data(classes, drivers, runs ++ extra_runs)

    :ok
  end
end
