defmodule Conecerto.Scoreboard.LoadTest do
  use Conecerto.Scoreboard.DataCase

  alias Conecerto.Scoreboard

  # test "load all data" do
  #   assert {:ok, config} = Scoreboard.MJ.Config.read("c:\\mjtiming", "2022_10_16")
  #   assert {:ok, result} = Scoreboard.load_data(config)
  # end

  test "select view" do
    Scoreboard.list_raw_scores()
  end
end
