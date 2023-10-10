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
