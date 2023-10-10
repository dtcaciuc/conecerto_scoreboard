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

    group_names =
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
        group_names: group_names
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
