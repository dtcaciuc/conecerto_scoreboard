defmodule Conecerto.ScoreboardWeb.Colors do
  require Logger

  alias Conecerto.Scoreboard.MJ.CSVParser

  @default_colors %{
    "body-text" => "white",
    "body-fill" => "#171717",
    "panel-fill" => "#262626",
    "header-fill" => "#262626",
    "header-border" => "#404040",
    "header-active-text" => "#EF4444",
    "table-stripe-fill" => "#383838",
    "table-selected-text" => "#FCD34D"
  }

  def default_colors(),
    do: @default_colors

  def read_colors(nil),
    do: @default_colors

  def read_colors(path) do
    try do
      path
      |> File.stream!()
      |> CSVParser.parse_stream_reversed()
      |> Enum.reduce(%{}, &parse_color_row/2)
      |> validate_colors()
    rescue
      err in File.Error ->
        Logger.error("Could not read #{path} - #{inspect(err)}")
        @default_colors
    end
  end

  defp parse_color_row(%{"name" => date, "value" => name}, colors),
    do: Map.put(colors, date, name)

  defp validate_colors(colors) do
    missing =
      key_set(@default_colors)
      |> MapSet.difference(key_set(colors))
      |> MapSet.to_list()

    if Enum.count(missing) == 0 do
      colors
    else
      raise "The following color(s) must be defined: #{inspect(missing)}"
    end
  end

  defp key_set(%{} = m),
    do: m |> Map.keys() |> MapSet.new()
end
