defmodule Conecerto.Scoreboard.RawScoresTest do
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

  test "list_raw_scores" do
    assert results = Scoreboard.list_raw_scores()
    assert 56 = Enum.count(results)

    [_ | [r1 | _]] = results

    assert %{
             car_class: "SSP",
             car_model: "'01 Honda Civic",
             car_no: 27,
             driver_name: "Allen, Jess",
             pos: 2,
             raw_time: 42.271,
             raw_time_to_next: 0.3680000000000021,
             raw_time_to_top: 0.3680000000000021,
             score: 99.12942679378297
           } = r1
  end
end
