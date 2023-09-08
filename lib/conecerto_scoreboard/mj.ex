defmodule Conecerto.Scoreboard.MJ.CSVParser do
  @moduledoc """
  CSVParser parses relaxed CSV format used by MJTiming.

  In it:

  * Fields are delimited by a comma
  * Unpaired quotations can occur freely inside field values
  * Columns have headers

  """
  require Logger

  defmodule Data do
    defstruct fields: %{}, rows: []
  end

  @doc """
  Parse CSV stream and output a list of row maps in reverse order.
  """
  def parse_stream_reversed(stream) do
    data =
      stream
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.split(&1, ","))
      |> Enum.reduce_while(%Data{}, &parse_row/2)

    data.rows
  end

  defp parse_row(fields, %Data{fields: %{}, rows: []} = data) do
    {:cont, %{data | fields: fields}}
  end

  defp parse_row(values, %Data{fields: fields, rows: rows} = data) do
    if Enum.count(fields) == Enum.count(values) do
      row = Enum.zip(fields, values) |> Map.new()
      {:cont, %{data | rows: [row | rows]}}
    else
      Logger.warning("Could not parse row with mismatched number of fields: #{inspect(values)}")
      {:cont, data}
    end
  end
end

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

defmodule Conecerto.Scoreboard.MJ.Classes do
  require Logger

  def read(path) do
    try do
      File.stream!(path)
      |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
      |> Enum.reduce([], &parse_row/2)
    rescue
      _ in File.Error -> []
    end
  end

  defp parse_row(
         %{"Class" => name, "PAX" => pax, "Description" => descr},
         classes
       ) do
    # Handle numbers without leading zero (e.g. 0.811)
    pax =
      if String.first(pax) == "." do
        "0" <> pax
      else
        pax
      end

    case Float.parse(pax) do
      {pax_f, ""} ->
        [%{name: name, pax: pax_f, description: descr} | classes]

      _ ->
        Logger.warning("Could not parse PAX multiplier '#{pax}' for class '#{name}'")
        classes
    end
  end

  defp parse_row(row, classes) do
    Logger.warning("Could not read an incomplete class definition: #{inspect(row)}")
    classes
  end
end

defmodule Conecerto.Scoreboard.MJ.Drivers do
  require Logger

  def read(path) do
    try do
      path
      |> File.stream!()
      |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
      |> Enum.reduce([], &parse_row/2)
    rescue
      _ in File.Error -> []
    end
  end

  defp parse_row(
         %{
           "Number" => car_no,
           "First Name" => first_name,
           "Last Name" => last_name,
           "Car Model" => car_model,
           "Class" => car_class,
           "Group" => group,
           "XGroup" => x_groups
         },
         drivers
       ) do
    # TODO car number into string; we need to be able to preserve leading zeros
    {car_no_i, ""} = Integer.parse(car_no)

    groups =
      [group | split_xgroups(x_groups)]
      |> Enum.filter(&(String.length(&1) > 0))

    # Abbreviate model year
    car_model =
      if String.match?(car_model, ~r/^\d{4}/) do
        "'" <> String.slice(car_model, 2..-1)
      else
        car_model
      end

    [
      %{
        id: car_no_i,
        first_name: first_name,
        last_name: last_name,
        car_no: car_no_i,
        car_model: car_model,
        car_class: car_class,
        groups: groups
      }
      | drivers
    ]
  end

  defp parse_row(row, drivers) do
    Logger.warning("Could not read an incomplete driver definition: #{inspect(row)}")
    drivers
  end

  defp split_xgroups(""), do: []
  defp split_xgroups(x_groups), do: String.split(x_groups, ";")
end

defmodule Conecerto.Scoreboard.MJ.Runs do
  require Logger

  def read_last_day(path) do
    rows =
      try do
        File.stream!(path)
        |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
        |> Enum.reduce([], &parse_row/2)
      rescue
        _ in File.Error -> []
      end

    last_day =
      if Enum.count(rows) > 0 do
        rows
        |> Enum.map(& &1.day)
        |> Enum.max()
      else
        1
      end

    rows
    |> Enum.filter(&(&1.day == last_day))
    |> Enum.map(&Map.delete(&1, :day))
  end

  defp parse_row(
         %{"car_number" => car_no, "day" => day, "penalty" => penalty, "run_time" => run_time},
         runs
       ) do
    with {parsed_day, ""} <- Integer.parse(day),
         {parsed_car_no, ""} <- Integer.parse(car_no),
         {parsed_time, ""} <- Float.parse(run_time) do
      [
        %{
          day: parsed_day,
          car_no: parsed_car_no,
          run_time: parsed_time,
          penalty: penalty
        }
        | runs
      ]
    else
      _ ->
        runs
    end
  end

  defp parse_row(row, runs) do
    Logger.warning("Could not read an incomplete run definition: #{inspect(row)}")
    runs
  end
end
