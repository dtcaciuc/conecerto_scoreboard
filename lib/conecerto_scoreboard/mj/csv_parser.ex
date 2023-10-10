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
