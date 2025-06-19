defmodule Conecerto.Scoreboard.MJ.Drivers do
  require Logger

  def read(path, opts \\ []) do
    {group_by_class?, _} = Keyword.pop(opts, :group_by_class?, false)

    try do
      path
      |> File.stream!()
      |> Conecerto.Scoreboard.MJ.CSVParser.parse_stream_reversed()
      |> Enum.reduce(%{group_by_class?: group_by_class?, drivers: []}, &parse_row/2)
      |> then(& &1.drivers)
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
         state
       ) do
    # TODO car number into string; we need to be able to preserve leading zeros
    {car_no_i, ""} = Integer.parse(car_no)

    group_names =
      if state.group_by_class? do
        [car_class]
      else
        [group | split_xgroups(x_groups)]
        |> Enum.filter(&(String.length(&1) > 0))
      end

    # Abbreviate model year
    car_model =
      if String.match?(car_model, ~r/^\d{4}/) do
        "'" <> String.slice(car_model, 2..-1//1)
      else
        car_model
      end

    drivers =
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
        | state.drivers
      ]

    %{state | drivers: drivers}
  end

  defp parse_row(row, state) do
    Logger.warning("Could not read an incomplete driver definition: #{inspect(row)}")
    state
  end

  defp split_xgroups(""), do: []
  defp split_xgroups(x_groups), do: String.split(x_groups, ";")
end
