defmodule Conecerto.Scoreboard.MJConfigTest do
  use ExUnit.Case

  alias Conecerto.Scoreboard.MJ

  test "read MJ timing config file" do
    mj_root = Path.join([__DIR__, "data", "mj_1"])

    assert {:ok, config} = MJ.Config.read(mj_root, "2016_10_11")

    assert config.root_path == mj_root
    assert String.ends_with?(config.class_data_path, "_classData.csv")
    assert String.ends_with?(config.event_data_path, "eventdata")
    assert String.ends_with?(config.event_run_data_path, "2016_10_11_timingData.csv")
    assert String.ends_with?(config.event_driver_data_path, "2016_10_11_driverData.csv")
  end
end

defmodule Conecerto.Scoreboard.MJClassTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Conecerto.Scoreboard.MJ

  test "read MJ class definitions" do
    assert [c1, c2, c3] = MJ.Classes.read(Path.join([__DIR__, "data", "classes_1.csv"]))

    assert %{
             name: "GS",
             pax: 0.794,
             description: "G Street"
           } = c1

    assert %{
             name: "SMF",
             pax: 0.847,
             description: "Street Modified F"
           } = c2

    assert %{
             name: "No\"vice",
             pax: 1.0,
             description: "Novice group"
           } = c3
  end

  test "return empty list if class file does not exist" do
    assert [] = MJ.Classes.read("doesnotexist")
  end

  test "return empty list if class file is missing columns" do
    assert capture_log(fn ->
             assert [] =
                      MJ.Classes.read(Path.join([__DIR__, "data", "classes_missing_columns.csv"]))
           end) =~ "Could not read an incomplete class definition"
  end
end

defmodule Conecerto.Scoreboard.MJDriversTest do
  use ExUnit.Case

  alias Conecerto.Scoreboard.MJ

  test "read MJ driver definitions" do
    assert [d1, d2, d3] = MJ.Drivers.read(Path.join([__DIR__, "data", "drivers_1.csv"]))

    assert %{
             id: 49,
             first_name: "Dan",
             last_name: "Hooper",
             car_no: 49,
             car_model: "'97 Acura Integra",
             car_class: "SMF",
             groups: ["Race", "Novice"]
           } = d1

    assert %{
             id: 102,
             first_name: "Angelina",
             last_name: "Hodge",
             car_no: 102,
             car_model: "'05 Subaru Impreza",
             car_class: "GS",
             groups: ["Street 1", "Ladies", "Novice"]
           } = d2

    assert %{
             id: 300,
             first_name: "Joe \"Quads\"",
             last_name: "Driver",
             car_no: 300,
             car_model: "Unknown",
             car_class: "",
             # FIXME Should not have an empty group name.
             groups: [""]
           } = d3
  end

  test "return empty list if class file fails to read" do
    assert [] = MJ.Drivers.read("doesnotexist")
  end
end

defmodule Conecerto.Scoreboard.MJRunsTest do
  use ExUnit.Case

  alias Conecerto.Scoreboard.MJ

  test "read MJ runs" do
    assert [r1, r2, r3] = MJ.Runs.read_last_day(Path.join([__DIR__, "data", "runs_1.csv"]))
    assert %{car_no: 58, penalty: "", run_time: 40.676} = r1
    assert %{car_no: 13, penalty: "DNF", run_time: 41.012} = r2
    assert %{car_no: 69, penalty: "RRN", run_time: 87.915} = r3
  end

  test "return empty list if runs file fails to read" do
    assert [] = MJ.Runs.read_last_day("doesnotexist")
  end
end
