defmodule Conecerto.Scoreboard.ConesTest do
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

  test "list_total_cones" do
    assert drivers = Scoreboard.list_total_cones()
    # The rest of drivers have no cones
    assert 75 = Enum.count(drivers)
    assert drivers |> Enum.map(&(&1.num_cones > 0)) |> Enum.all?()

    # Pick a driver w/ clean run, rerun, cone penalty
    assert {:ok, %{car_no: 58, num_cones: 6}} = Enum.fetch(drivers, 21)
  end
end
