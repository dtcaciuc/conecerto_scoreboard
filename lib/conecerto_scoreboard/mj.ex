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
      |> CSV.Decoding.Decoder.decode()
      |> Enum.reduce(%Config{root_path: mj_dir}, &parse_row(date, &1, &2))

    {:ok, config}
  end

  defp parse_row(_date, {:ok, ["classDataFile", val, _descr]}, config) do
    val = val |> String.replace("\\", "/")
    %{config | class_data_path: val}
  end

  defp parse_row(date, {:ok, ["eventDataFolder", val, _descr]}, config) do
    val = val |> String.replace("\\", "/")

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
  def read(path) do
    try do
      File.stream!(path)
      |> CSV.Decoding.Decoder.decode(headers: true)
      |> Enum.reduce([], &parse_row/2)
      |> Enum.reverse()
    rescue
      _ in File.Error -> []
    end
  end

  defp parse_row(
         {:ok, %{"Class" => name, "PAX" => pax, "Description" => descr}},
         classes
       ) do
    {pax_f, ""} = Float.parse(pax)
    [%{name: name, pax: pax_f, description: descr} | classes]
  end
end

defmodule Conecerto.Scoreboard.MJ.Drivers do
  def read(path) do
    try do
      File.stream!(path)
      |> CSV.Decoding.Decoder.decode(headers: true)
      |> Enum.reduce([], &parse_row/2)
      |> Enum.reverse()
    rescue
      _ in File.Error -> []
    end
  end

  defp parse_row(
         {:ok,
          %{
            "Number" => car_no,
            "First Name" => first_name,
            "Last Name" => last_name,
            "Car Model" => car_model,
            "Class" => car_class,
            "Group" => group,
            "XGroup" => x_groups
          }},
         drivers
       ) do
    {car_no_i, ""} = Integer.parse(car_no)
    groups = [group | split_xgroups(x_groups)]

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

  defp split_xgroups(""), do: []
  defp split_xgroups(x_groups), do: String.split(x_groups, ";")
end

defmodule Conecerto.Scoreboard.MJ.Runs do
  def read_last_day(path) do
    rows =
      try do
        File.stream!(path)
        |> CSV.Decoding.Decoder.decode(headers: true)
        |> Enum.reduce([], &parse_row/2)
        |> Enum.reverse()
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
         {:ok,
          %{"car_number" => car_no, "day" => day, "penalty" => penalty, "run_time" => run_time}},
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
end
