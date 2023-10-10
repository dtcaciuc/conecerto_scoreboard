defmodule Conecerto.Scoreboard.GroupScoresTest do
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

  test "list_all_group_scores" do
    assert groups = Scoreboard.list_all_group_scores()

    assert [
             "Ladies",
             "Novice",
             "Race",
             "Street 1",
             "Street 2",
             "Street 3",
             "Touring 1",
             "Touring 2"
           ] =
             for(g <- groups, do: g.name)

    for g <- groups do
      assert g.scores == Scoreboard.list_group_scores(g.name)
    end

    [ladies | _] = groups

    assert [s1, s2, s3] = ladies.scores

    assert %{
             group_name: "Ladies",
             pos: 1,
             car_no: 85,
             driver_name: "Browning, Diane",
             car_class: "DSP",
             car_model: "'86 Nissan 300ZX",
             pax_time: 35.366132,
             raw_time_to_top: 0.0,
             raw_time_to_next: nil
           } = s1

    assert %{
             group_name: "Ladies",
             pos: 2,
             car_no: 71,
             driver_name: "Maciejewski, Clarissa",
             car_class: "SS",
             car_model: "'19 Tesla 3",
             pax_time: 35.414995,
             raw_time_to_top: 0.05865906362544684,
             raw_time_to_next: 0.05865906362544684
           } = s2

    assert %{
             group_name: "Ladies",
             pos: 3,
             car_no: 11,
             driver_name: "Gonzalez, Megan",
             car_class: "ES",
             car_model: "'99 Mazda Miata",
             pax_time: 37.866312,
             raw_time_to_top: 3.1567929292929295,
             raw_time_to_next: 3.095097222222226
           } = s3
  end
end
