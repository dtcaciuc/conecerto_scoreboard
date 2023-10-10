defmodule Conecerto.Scoreboard.MJ.Config do
  use TypedStruct

  alias Conecerto.Scoreboard.MJ.Config

  typedstruct do
    field :root_path, String.t()
    field :class_data_path, String.t()
    field :event_data_path, String.t()
    field :event_run_data_path, String.t()
    field :event_driver_data_path, String.t()
  end

  def read(mj_dir, date) do
    config =
      Path.join([mj_dir, "config", "configData.csv"])
      |> File.stream!()
      |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
      |> Enum.reduce(%Config{root_path: mj_dir}, &parse_row(date, &1, &2))

    {:ok, config}
  end

  defp parse_row(_date, %{"Parameter" => "classDataFile", "Value" => val}, config) do
    %{config | class_data_path: Path.absname(val)}
  end

  defp parse_row(date, %{"Parameter" => "eventDataFolder", "Value" => val}, config) do
    val = Path.absname(val)

    %{
      config
      | event_data_path: val,
        event_run_data_path: Path.join(val, "#{date}_timingData.csv"),
        event_driver_data_path: Path.join(val, "#{date}_driverData.csv")
    }
  end

  defp parse_row(_date, _row, config) do
    config
  end
end
